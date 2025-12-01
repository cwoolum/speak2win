import Foundation
import SwiftUI

enum RecordingState {
    case idle
    case recording
    case transcribing
}

enum HotkeyOption: String, CaseIterable {
    case fnKey = "fn"
    case rightOption = "rightOption"
    case rightCommand = "rightCommand"
    case hyperKey = "hyperKey"
    case ctrlOptionSpace = "ctrlOptionSpace"

    var displayName: String {
        switch self {
        case .fnKey: return "Fn (hold)"
        case .rightOption: return "Right Option (hold)"
        case .rightCommand: return "Right Command (hold)"
        case .hyperKey: return "Hyper Key (hold) – Ctrl+Opt+Cmd+Shift"
        case .ctrlOptionSpace: return "Ctrl+Option+Space (hold)"
        }
    }

    static var saved: HotkeyOption {
        get {
            if let raw = UserDefaults.standard.string(forKey: "hotkeyOption"),
               let option = HotkeyOption(rawValue: raw) {
                return option
            }
            return .fnKey
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "hotkeyOption")
        }
    }
}

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var recordingState: RecordingState = .idle
    @Published var isModelLoaded: Bool = false
    @Published var hasAccessibilityPermission: Bool = false
    @Published var hasMicrophonePermission: Bool = false
    @Published var modelDownloadProgress: Double = 0.0
    @Published var lastError: String? = nil

    private init() {}

    var isSetupComplete: Bool {
        isModelLoaded && hasAccessibilityPermission && hasMicrophonePermission
    }
}
