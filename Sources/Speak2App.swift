import SwiftUI

@main
struct Speak2App: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)

        // Setup menu bar
        statusBarController = StatusBarController()
        statusBarController?.setup()
    }
}
