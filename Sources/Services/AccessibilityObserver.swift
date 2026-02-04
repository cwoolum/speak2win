import ApplicationServices
import Foundation

/// Event-driven accessibility observer that wraps AXObserver for async/await usage.
/// Provides non-polling detection of UI element changes via macOS accessibility notifications.
final class AccessibilityObserver: @unchecked Sendable {

    enum ObserverError: Error {
        case failedToCreateObserver
        case failedToAddNotification
        case elementNotObservable
        case timeout
        case cancelled
    }

    /// Notifications we monitor for paste completion detection
    static let textChangeNotifications: [String] = [
        kAXValueChangedNotification as String,
        kAXSelectedTextChangedNotification as String
    ]

    private var observer: AXObserver?
    private var continuation: CheckedContinuation<Void, Error>?
    private let lock = NSLock()

    deinit {
        cleanup()
    }

    /// Wait for any text-related change on the given element.
    /// Returns when a notification fires, or throws on timeout/cancellation.
    func waitForTextChange(
        on element: AXUIElement,
        timeout: Duration
    ) async throws {
        // Get the PID for this element
        var pid: pid_t = 0
        let pidResult = AXUIElementGetPid(element, &pid)
        guard pidResult == .success else {
            throw ObserverError.elementNotObservable
        }

        // Create the observer with our callback
        var observerRef: AXObserver?
        let callbackContext = Unmanaged.passUnretained(self).toOpaque()

        let createResult = AXObserverCreate(
            pid,
            accessibilityCallback,
            &observerRef
        )

        guard createResult == .success, let observer = observerRef else {
            throw ObserverError.failedToCreateObserver
        }

        self.observer = observer

        // Add notifications we care about
        var addedAny = false
        for notification in Self.textChangeNotifications {
            let addResult = AXObserverAddNotification(
                observer,
                element,
                notification as CFString,
                callbackContext
            )
            if addResult == .success {
                addedAny = true
            }
        }

        guard addedAny else {
            cleanup()
            throw ObserverError.failedToAddNotification
        }

        // Add observer to run loop
        let runLoopSource = AXObserverGetRunLoopSource(observer)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        // Wait for notification or timeout
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                lock.lock()
                self.continuation = cont
                lock.unlock()

                // Set up timeout
                Task {
                    try await Task.sleep(for: timeout)
                    self.timeoutReached()
                }
            }
        } catch {
            cleanup()
            throw error
        }

        cleanup()
    }

    /// Check if an element supports the notifications we need for paste detection
    static func supportsTextChangeNotifications(element: AXUIElement) -> Bool {
        // Try to get the role - text fields, text areas, and combo boxes typically support notifications
        var roleRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
        guard result == .success, let role = roleRef as? String else {
            return false
        }

        // These roles typically support value/selection change notifications
        let observableRoles: Set<String> = [
            kAXTextFieldRole as String,
            kAXTextAreaRole as String,
            kAXComboBoxRole as String
        ]

        return observableRoles.contains(role)
    }

    // MARK: - Private

    fileprivate func notificationReceived() {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()

        cont?.resume(returning: ())
    }

    private func timeoutReached() {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()

        cont?.resume(throwing: ObserverError.timeout)
    }

    private func cleanup() {
        lock.lock()
        if let observer = observer {
            let runLoopSource = AXObserverGetRunLoopSource(observer)
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
            self.observer = nil
        }
        lock.unlock()
    }
}

// C-style callback for AXObserver - must be a free function
private func accessibilityCallback(
    observer: AXObserver,
    element: AXUIElement,
    notification: CFString,
    refcon: UnsafeMutableRawPointer?
) {
    guard let refcon = refcon else { return }
    let observer = Unmanaged<AccessibilityObserver>.fromOpaque(refcon).takeUnretainedValue()
    observer.notificationReceived()
}
