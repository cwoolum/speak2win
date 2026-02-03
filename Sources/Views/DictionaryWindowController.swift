import AppKit
import SwiftUI

extension Notification.Name {
    static let openDictionaryWindow = Notification.Name("openDictionaryWindow")
    static let showQuickAddWord = Notification.Name("showQuickAddWord")
}

@MainActor
class DictionaryWindowController: NSObject {
    private var window: NSWindow?

    func showDictionaryWindow() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let dictionaryView = DictionaryView()
            .environmentObject(AppState.shared.dictionaryState)
        let hostingController = NSHostingController(rootView: dictionaryView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Personal Dictionary"
        newWindow.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        newWindow.setContentSize(NSSize(width: 650, height: 500))
        newWindow.minSize = NSSize(width: 500, height: 400)
        newWindow.center()

        newWindow.delegate = self
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = newWindow
    }

    func closeDictionaryWindow() {
        window?.close()
        window = nil
    }
}

extension DictionaryWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
