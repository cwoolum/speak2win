import Foundation
import SwiftUI

enum RecordingState {
    case idle
    case loadingModel
    case recording
    case transcribing
}

enum TranscriptionModel: String, CaseIterable {
    case whisperBaseEn = "whisper-base.en"
    case parakeetV3 = "parakeet-v3"

    var displayName: String {
        switch self {
        case .whisperBaseEn: return "Whisper (base.en)"
        case .parakeetV3: return "Parakeet v3"
        }
    }

    var description: String {
        switch self {
        case .whisperBaseEn: return "English only – fast and accurate"
        case .parakeetV3: return "25 languages – best for multilingual users"
        }
    }

    var estimatedSize: String {
        switch self {
        case .whisperBaseEn: return "~140 MB"
        case .parakeetV3: return "~600 MB"
        }
    }

    /// Path where this model's files are stored
    var storagePath: URL {
        switch self {
        case .whisperBaseEn:
            return FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Documents/huggingface")
        case .parakeetV3:
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("FluidAudio")
        }
    }

    /// Check if this model is downloaded by looking for files on disk
    var isDownloaded: Bool {
        let path = storagePath
        guard FileManager.default.fileExists(atPath: path.path) else { return false }
        // Check if directory has content
        let contents = try? FileManager.default.contentsOfDirectory(atPath: path.path)
        return (contents?.count ?? 0) > 0
    }

    static var saved: TranscriptionModel {
        get {
            if let raw = UserDefaults.standard.string(forKey: "transcriptionModel"),
               let model = TranscriptionModel(rawValue: raw) {
                return model
            }
            return .whisperBaseEn
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "transcriptionModel")
        }
    }
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

    // Model selection
    @Published var selectedModel: TranscriptionModel = TranscriptionModel.saved
    @Published var currentlyLoadedModel: TranscriptionModel? = nil
    @Published var downloadedModels: Set<TranscriptionModel> = []

    // Personal dictionary
    let dictionaryState = DictionaryState()

    private init() {
        refreshDownloadedModels()
        dictionaryState.load()
    }

    var isSetupComplete: Bool {
        isModelLoaded && hasAccessibilityPermission && hasMicrophonePermission
    }

    /// Refresh the set of downloaded models by checking filesystem
    func refreshDownloadedModels() {
        downloadedModels = Set(TranscriptionModel.allCases.filter { $0.isDownloaded })
    }
}
