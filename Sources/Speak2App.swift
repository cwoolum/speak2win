import SwiftUI
import AppKit
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
    private var dictionaryWindowController: DictionaryWindowController?
    private var historyWindowController: TranscriptionHistoryWindowController?
    private var quickAddWindow: NSWindow?
    private var addToDictionaryWindow: NSWindow?
    private var dictationController: DictationController?
    private let appState = AppState.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasStartedDictation = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)

        // Register as service provider for right-click "Add to Dictionary"
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()

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

        // Listen for requests to open dictionary window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenDictionaryWindow),
            name: .openDictionaryWindow,
            object: nil
        )

        // Listen for requests to show quick add
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowQuickAdd),
            name: .showQuickAddWord,
            object: nil
        )

        // Listen for requests to open history window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenHistoryWindow),
            name: .openHistoryWindow,
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

    @objc private func handleOpenDictionaryWindow() {
        Task { @MainActor in
            showDictionaryWindow()
        }
    }

    @objc private func handleShowQuickAdd() {
        Task { @MainActor in
            showQuickAddWindow()
        }
    }

    @objc private func handleOpenHistoryWindow() {
        Task { @MainActor in
            showHistoryWindow()
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

    @MainActor
    private func showDictionaryWindow() {
        if dictionaryWindowController == nil {
            dictionaryWindowController = DictionaryWindowController()
        }
        dictionaryWindowController?.showDictionaryWindow()
    }

    @MainActor
    private func showHistoryWindow() {
        if historyWindowController == nil {
            historyWindowController = TranscriptionHistoryWindowController()
        }
        historyWindowController?.showHistoryWindow()
    }

    @MainActor
    private func showQuickAddWindow() {
        // Close existing quick add window if open
        quickAddWindow?.close()

        let quickAddView = QuickAddSheet()
            .environmentObject(appState.dictionaryState)
        let hostingController = NSHostingController(rootView: quickAddView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Add Word"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 300, height: 260))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        quickAddWindow = window
    }

    func applicationWillTerminate(_ notification: Notification) {
        dictationController?.stop()
    }

    // MARK: - Services Provider

    /// Handle the "Add to Speak2 Dictionary" service from right-click menu
    @objc func addToDictionary(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pboard.string(forType: .string), !text.isEmpty else {
            error.pointee = "No text selected" as NSString
            return
        }

        Task { @MainActor in
            showAddToDictionaryWindow(selectedText: text)
        }
    }

    @MainActor
    private func showAddToDictionaryWindow(selectedText: String) {
        // Close existing window if open
        addToDictionaryWindow?.close()

        let addView = AddToDictionarySheet(selectedText: selectedText)
            .environmentObject(appState.dictionaryState)
        let hostingController = NSHostingController(rootView: addView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Add to Dictionary"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        addToDictionaryWindow = window
    }
}
