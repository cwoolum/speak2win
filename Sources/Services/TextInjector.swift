import AppKit
import ApplicationServices
import Carbon.HIToolbox

@MainActor
final class TextInjector {
    private enum OriginalClipboard {
        case empty
        case items([NSPasteboardItem])
        case unrecoverable
    }

    private struct ClipboardSession {
        let original: OriginalClipboard
        let id: UUID
        let injectedChangeCount: Int
        let injectedText: String
    }

    private var session: ClipboardSession?
    private var restoreTask: Task<Void, Never>?

    func inject(text: String) {
        let pasteboard = NSPasteboard.general

        let original: OriginalClipboard
        if let existingSession = session, pasteboard.changeCount == existingSession.injectedChangeCount {
            original = existingSession.original
        } else {
            session = nil
            original = snapshotOriginalClipboard(from: pasteboard)
        }

        restoreTask?.cancel()
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let injectedChangeCount = pasteboard.changeCount
        let sessionId = UUID()
        session = ClipboardSession(
            original: original,
            id: sessionId,
            injectedChangeCount: injectedChangeCount,
            injectedText: text
        )

        // Small delay to ensure clipboard is ready
        usleep(50000) // 50ms

        let focusedElement = fetchFocusedUIElement()
        let baseline = focusedElement.map { snapshotTextState(of: $0) }

        // Simulate Cmd+V
        simulatePaste()

        // Restore prior clipboard contents after paste is likely consumed.
        // Prefer a content-change signal from the focused UI element; fall back to a conservative timeout.
        restoreTask = Task { @MainActor in
            await restoreClipboardAfterPaste(
                on: pasteboard,
                sessionId: sessionId,
                focusedElement: focusedElement,
                baseline: baseline
            )
        }
    }

    private func snapshotOriginalClipboard(from pasteboard: NSPasteboard) -> OriginalClipboard {
        guard let items = pasteboard.pasteboardItems, !items.isEmpty else { return .empty }

        let snapshots: [NSPasteboardItem] = items.compactMap { item in
            let snapshot = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    snapshot.setData(data, forType: type)
                } else if let string = item.string(forType: type) {
                    snapshot.setString(string, forType: type)
                } else if let propertyList = item.propertyList(forType: type) {
                    snapshot.setPropertyList(propertyList, forType: type)
                }
            }
            return snapshot.types.isEmpty ? nil : snapshot
        }

        if !snapshots.isEmpty {
            return .items(snapshots)
        }

        // Clipboard wasn't empty, but we couldn't snapshot any writable types.
        return .unrecoverable
    }

    private struct TextStateSnapshot: Equatable {
        let selectedTextRange: NSRange?
        let numberOfCharacters: Int?

        var hasSignal: Bool {
            selectedTextRange != nil || numberOfCharacters != nil
        }
    }

    private func indicatesPasteConsumed(baseline: TextStateSnapshot, current: TextStateSnapshot) -> Bool {
        if let baselineRange = baseline.selectedTextRange, let currentRange = current.selectedTextRange {
            if baselineRange != currentRange { return true }
        }

        if let baselineCount = baseline.numberOfCharacters, let currentCount = current.numberOfCharacters {
            if baselineCount != currentCount { return true }
        }

        return false
    }

    private func fetchFocusedUIElement() -> AXUIElement? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focused)
        guard error == .success, let focused else { return nil }
        return (focused as! AXUIElement)
    }

    private func snapshotTextState(of element: AXUIElement) -> TextStateSnapshot {
        TextStateSnapshot(
            selectedTextRange: copyRangeAttribute(of: element, attribute: kAXSelectedTextRangeAttribute),
            numberOfCharacters: copyIntAttribute(of: element, attribute: kAXNumberOfCharactersAttribute)
        )
    }

    private func copyIntAttribute(of element: AXUIElement, attribute: String) -> Int? {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)
        guard error == .success, let rawValue else { return nil }
        if let numberValue = rawValue as? NSNumber {
            return numberValue.intValue
        }
        return rawValue as? Int
    }

    private func copyRangeAttribute(of element: AXUIElement, attribute: String) -> NSRange? {
        var rawValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &rawValue)
        guard error == .success, let rawValue else { return nil }
        guard CFGetTypeID(rawValue) == AXValueGetTypeID() else { return nil }
        let axValue = (rawValue as! AXValue)

        var range = CFRange()
        guard AXValueGetType(axValue) == .cfRange, AXValueGetValue(axValue, .cfRange, &range) else { return nil }
        return NSRange(location: range.location, length: range.length)
    }

    private func restoreClipboardAfterPaste(
        on pasteboard: NSPasteboard,
        sessionId: UUID,
        focusedElement: AXUIElement?,
        baseline: TextStateSnapshot?
    ) async {
        // Prefer to restore only after we observe a change in the focused element.
        // The timeout is intentionally conservative to reduce the chance of restoring before a delayed paste is consumed.
        let pollIntervalNanos: UInt64 = 100_000_000 // 100ms
        let timeoutNanos: UInt64 = 30_000_000_000 // 30s

        var elapsed: UInt64 = 0
        while !Task.isCancelled {
            guard let currentSession = session, currentSession.id == sessionId else { return }

            // If the user/app changed the clipboard after we injected, don't restore.
            if pasteboard.changeCount != currentSession.injectedChangeCount {
                session = nil
                return
            }

            if let focusedElement, let baseline, baseline.hasSignal {
                let current = snapshotTextState(of: focusedElement)
                if current.hasSignal, indicatesPasteConsumed(baseline: baseline, current: current) {
                    restoreClipboard(on: pasteboard, session: currentSession)
                    return
                }
            }

            if elapsed >= timeoutNanos {
                restoreClipboard(on: pasteboard, session: currentSession)
                return
            }

            try? await Task.sleep(nanoseconds: pollIntervalNanos)
            elapsed += pollIntervalNanos
        }
    }

    private func restoreClipboard(on pasteboard: NSPasteboard, session: ClipboardSession) {
        guard self.session?.id == session.id else { return }
        guard pasteboard.changeCount == session.injectedChangeCount else {
            self.session = nil
            return
        }

        switch session.original {
        case .unrecoverable:
            break
        case .empty:
            pasteboard.clearContents()
        case .items(let items):
            let didWrite = pasteboard.writeObjects(items)
            if !didWrite {
                pasteboard.clearContents()
                pasteboard.setString(session.injectedText, forType: .string)
            }
        }
        self.session = nil
    }

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key code for 'V' is 9
        let keyCode: CGKeyCode = 9

        // Key down with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
        }

        // Key up with Command modifier
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
