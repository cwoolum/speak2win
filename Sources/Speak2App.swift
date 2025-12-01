import SwiftUI
import AVFoundation

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
    private var setupWindowController: SetupWindowController?
    private var dictationController: DictationController?
    private let appState = AppState.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)

        // Create dictation controller early so menu can reference it
        dictationController = DictationController()

        // Setup menu bar with reference to dictation controller
        statusBarController = StatusBarController()
        statusBarController?.setup(dictationController: dictationController)

        // Check if setup is needed
        Task { @MainActor in
            await checkAndStartDictation()
        }
    }

    @MainActor
    private func checkAndStartDictation() async {
        // Check permissions
        appState.hasAccessibilityPermission = HotkeyManager.checkAccessibilityPermission()

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            appState.hasMicrophonePermission = true
        default:
            appState.hasMicrophonePermission = false
        }

        // Show setup if needed
        if !appState.hasAccessibilityPermission || !appState.hasMicrophonePermission {
            showSetupWindow()
            return
        }

        // Start dictation
        do {
            try await dictationController?.start()
        } catch {
            appState.lastError = error.localizedDescription
            showSetupWindow()
        }
    }

    private func showSetupWindow() {
        setupWindowController = SetupWindowController()
        setupWindowController?.showSetupWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        dictationController?.stop()
    }
}
