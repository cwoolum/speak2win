import AppKit
import SwiftUI

extension Notification.Name {
    static let openSettingsWindow = Notification.Name("openSettingsWindow")
}

@MainActor
class SettingsWindowController: NSObject {
    private var window: NSWindow?
    private var modelManager: ModelManager?

    func showSettingsWindow(modelManager: ModelManager?) {
        self.modelManager = modelManager

        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(modelManager: modelManager)
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Speak2 Settings"
        newWindow.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        newWindow.setContentSize(NSSize(width: 800, height: 550))
        newWindow.minSize = NSSize(width: 750, height: 500)
        newWindow.center()

        // Use toolbar style for modern macOS look
        newWindow.toolbarStyle = .unified

        newWindow.delegate = self
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = newWindow
    }

    func closeSettingsWindow() {
        window?.close()
        window = nil
    }
}

extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
