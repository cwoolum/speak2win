import AppKit
import SwiftUI
import Combine
import ServiceManagement

@MainActor
class StatusBarController {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    private let appState = AppState.shared
    private weak var dictationController: DictationController?

    func setup(dictationController: DictationController?) {
        self.dictationController = dictationController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        guard let button = statusItem?.button else { return }
        button.imagePosition = .imageOnly
        updateIcon(for: .idle)

        setupMenu()
        observeState()
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Hotkey submenu
        let hotkeyMenu = NSMenu()
        for option in HotkeyOption.allCases {
            let item = NSMenuItem(
                title: option.displayName,
                action: #selector(hotkeySelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = option
            item.state = (option == HotkeyOption.saved) ? .on : .off
            hotkeyMenu.addItem(item)
        }

        let hotkeyItem = NSMenuItem(title: "Hotkey", action: nil, keyEquivalent: "")
        hotkeyItem.submenu = hotkeyMenu
        menu.addItem(hotkeyItem)

        // Launch at Login toggle
        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin(_:)),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Speak2", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            print("Failed to toggle launch at login: \(error)")
        }
    }

    @objc private func hotkeySelected(_ sender: NSMenuItem) {
        guard let option = sender.representedObject as? HotkeyOption else { return }

        // Update checkmarks
        if let menu = sender.menu {
            for item in menu.items {
                item.state = (item.representedObject as? HotkeyOption == option) ? .on : .off
            }
        }

        // Update the hotkey
        dictationController?.updateHotkey(option)
    }

    private func observeState() {
        appState.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateIcon(for: state)
            }
            .store(in: &cancellables)
    }

    private func updateIcon(for state: RecordingState) {
        guard let button = statusItem?.button else { return }

        let symbolName: String

        switch state {
        case .idle:
            symbolName = "mic"
        case .recording:
            symbolName = "mic.fill"
        case .transcribing:
            symbolName = "ellipsis.circle"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
            .applying(NSImage.SymbolConfiguration(textStyle: .body, scale: .medium))
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Speak2")?
            .withSymbolConfiguration(config) {
            // Use template mode for automatic light/dark mode adaptation
            image.isTemplate = true
            button.image = image

            // Only tint for active states (recording/transcribing)
            switch state {
            case .idle:
                button.contentTintColor = nil  // Let system handle it
            case .recording:
                button.contentTintColor = .systemRed
            case .transcribing:
                button.contentTintColor = .systemBlue
            }
        }
    }
}
