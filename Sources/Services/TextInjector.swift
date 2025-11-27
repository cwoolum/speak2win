import AppKit
import Carbon.HIToolbox

class TextInjector {
    func inject(text: String) {
        // Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to ensure clipboard is ready
        usleep(50000) // 50ms

        // Simulate Cmd+V
        simulatePaste()
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
