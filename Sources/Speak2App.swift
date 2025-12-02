import SwiftUI
import AVFoundation
import Combine

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
    private var cancellables = Set<AnyCancellable>()
    private var hasStartedDictation = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)

        // Create dictation controller early so menu can reference it
        dictationController = DictationController()

        // Setup menu bar with reference to dictation controller
        statusBarController = StatusBarController()
        statusBarController?.setup(dictationController: dictationController)

        // Listen for requests to open setup window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenSetupWindow),
            name: .openSetupWindow,
            object: nil
        )

        // Observe setup completion to start dictation
        observeSetupCompletion()

        // Check if setup is needed
        Task { @MainActor in
            await checkAndStartDictation()
        }
    }

    @objc private func handleOpenSetupWindow() {
        Task { @MainActor in
            showSetupWindow()
        }
    }

    @MainActor
    private func observeSetupCompletion() {
        // When setup becomes complete, start dictation if not already started
        appState.$isModelLoaded
            .combineLatest(appState.$hasAccessibilityPermission, appState.$hasMicrophonePermission)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isModelLoaded, hasAccessibility, hasMicrophone in
                guard let self = self else { return }
                if isModelLoaded && hasAccessibility && hasMicrophone && !self.hasStartedDictation {
                    self.hasStartedDictation = true
                    Task { @MainActor in
                        await self.startDictation()
                    }
                }
            }
            .store(in: &cancellables)
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

        // Show setup if needed (no model downloaded or missing permissions)
        let hasDownloadedModel = !appState.downloadedModels.isEmpty
        if !appState.hasAccessibilityPermission || !appState.hasMicrophonePermission || !hasDownloadedModel {
            showSetupWindow()
            return
        }

        // Start dictation
        await startDictation()
    }

    @MainActor
    private func startDictation() async {
        do {
            try await dictationController?.start()
            hasStartedDictation = true
        } catch {
            appState.lastError = error.localizedDescription
            showSetupWindow()
        }
    }

    @MainActor
    private func showSetupWindow() {
        if setupWindowController == nil {
            setupWindowController = SetupWindowController()
        }
        setupWindowController?.showSetupWindow(modelManager: dictationController?.modelManager)
    }

    func applicationWillTerminate(_ notification: Notification) {
        dictationController?.stop()
    }
}
