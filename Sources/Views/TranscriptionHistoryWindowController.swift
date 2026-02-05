import AppKit
import SwiftUI

extension Notification.Name {
    static let openHistoryWindow = Notification.Name("openHistoryWindow")
}

@MainActor
class TranscriptionHistoryWindowController: NSObject {
    private var window: NSWindow?

    func showHistoryWindow() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let historyView = TranscriptionHistoryView()
            .environmentObject(AppState.shared.historyState)
        let hostingController = NSHostingController(rootView: historyView)

        let newWindow = NSWindow(contentViewController: hostingController)
        newWindow.title = "Transcription History"
        newWindow.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        newWindow.setContentSize(NSSize(width: 700, height: 500))
        newWindow.minSize = NSSize(width: 600, height: 400)
        newWindow.center()

        newWindow.delegate = self
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = newWindow
    }

    func closeHistoryWindow() {
        window?.close()
        window = nil
    }
}

extension TranscriptionHistoryWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
