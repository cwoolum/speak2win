import AppKit
import SwiftUI

class SetupWindowController {
    private var window: NSWindow?

    func showSetupWindow() {
        if window != nil {
            window?.makeKeyAndOrderFront(nil)
            return
        }

        let setupView = SetupView()
        let hostingController = NSHostingController(rootView: setupView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Speak2 Setup"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)

        // Bring app to front
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
    }

    func closeSetupWindow() {
        window?.close()
        window = nil
    }
}
