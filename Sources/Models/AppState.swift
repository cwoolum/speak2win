import Foundation
import SwiftUI

enum RecordingState {
    case idle
    case recording
    case transcribing
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
