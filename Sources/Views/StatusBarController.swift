import AppKit
import SwiftUI
import Combine

@MainActor
class StatusBarController {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()
    private let appState = AppState.shared

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else { return }
        updateIcon(for: .idle)

        setupMenu()
        observeState()
    }

    private func setupMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit Speak2", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
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

        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
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
