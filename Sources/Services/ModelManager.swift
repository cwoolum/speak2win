import Foundation

/// Manages transcription model lifecycle: downloading, loading, switching, and deletion.
@MainActor
class ModelManager: ObservableObject {
    private var whisperTranscriber: WhisperTranscriber?
    private var parakeetTranscriber: ParakeetTranscriber?

    private let appState = AppState.shared

    /// The currently active transcription engine (if any model is loaded)
    var currentEngine: (any TranscriptionEngine)? {
        switch appState.currentlyLoadedModel {
        case .whisperBaseEn:
            return whisperTranscriber
        case .parakeetV3:
            return parakeetTranscriber
        case nil:
            return nil
        }
    }

    /// Load the specified model, unloading any currently loaded model first
    func loadModel(_ model: TranscriptionModel, progressHandler: @escaping (Double) -> Void) async throws {
        // Unload current model if different
        if let current = appState.currentlyLoadedModel, current != model {
            await unloadCurrentModel()
        }

        // Skip if already loaded
        if appState.currentlyLoadedModel == model {
            progressHandler(1.0)
            return
        }

        appState.isModelLoaded = false
        appState.modelDownloadProgress = 0.0
        appState.recordingState = .loadingModel

        switch model {
        case .whisperBaseEn:
            let transcriber = WhisperTranscriber()
            try await transcriber.loadModel { progress in
                Task { @MainActor in
                    self.appState.modelDownloadProgress = progress
                    progressHandler(progress)
                }
            }
            whisperTranscriber = transcriber

        case .parakeetV3:
            let transcriber = ParakeetTranscriber()
            try await transcriber.loadModel { progress in
                Task { @MainActor in
                    self.appState.modelDownloadProgress = progress
                    progressHandler(progress)
                }
            }
            parakeetTranscriber = transcriber
        }

        appState.currentlyLoadedModel = model
        appState.selectedModel = model
        TranscriptionModel.saved = model
        appState.isModelLoaded = true
        appState.recordingState = .idle
        appState.refreshDownloadedModels()
    }

    /// Unload the currently loaded model to free memory
    func unloadCurrentModel() async {
        if let whisper = whisperTranscriber {
            await whisper.unloadModel()
            whisperTranscriber = nil
        }
        if let parakeet = parakeetTranscriber {
            await parakeet.unloadModel()
            parakeetTranscriber = nil
        }
        appState.currentlyLoadedModel = nil
        appState.isModelLoaded = false
    }

    /// Delete a model's files from disk
    func deleteModel(_ model: TranscriptionModel) async throws {
        // Unload if this is the current model
        if appState.currentlyLoadedModel == model {
            await unloadCurrentModel()
        }

        let path = model.storagePath
        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }

        appState.refreshDownloadedModels()
    }

    /// Transcribe audio using the currently loaded model
    /// - Parameters:
    ///   - audioURL: Path to the audio file
    ///   - dictionaryHint: Optional comma-separated list of words to prioritize
    /// - Returns: Transcribed text
    func transcribe(audioURL: URL, dictionaryHint: String? = nil) async throws -> String {
        guard let engine = currentEngine else {
            throw TranscriptionEngineError.modelNotLoaded
        }
        return try await engine.transcribe(audioURL: audioURL, dictionaryHint: dictionaryHint)
    }
}
