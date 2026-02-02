import Foundation
import WhisperKit

actor WhisperTranscriber: TranscriptionEngine {
    private var whisperKit: WhisperKit?
    private var isLoading = false

    var isModelLoaded: Bool {
        whisperKit != nil
    }

    /// Load a Whisper model by variant string (e.g. "base.en", "small.en", "large-v3").
    /// Returns the model folder URL so the caller can persist it for isDownloaded/delete.
    func loadModel(variant: String, progressHandler: @escaping (Double) -> Void) async throws -> URL {
        guard !isLoading && whisperKit == nil else {
            throw TranscriptionEngineError.modelNotLoaded
        }
        isLoading = true

        defer { isLoading = false }

        // Download model first with progress tracking
        let modelFolder = try await WhisperKit.download(
            variant: variant,
            progressCallback: { progress in
                Task { @MainActor in
                    progressHandler(progress.fractionCompleted)
                }
            }
        )

        // Initialize WhisperKit with the downloaded model (no re-download needed)
        let config = WhisperKitConfig(
            modelFolder: modelFolder.path,
            verbose: false,
            logLevel: .none,
            prewarm: true,
            load: true,
            download: false
        )

        whisperKit = try await WhisperKit(config)
        return modelFolder
    }

    // MARK: - TranscriptionEngine (protocol)

    /// Protocol conformance; uses default variant. Prefer loadModel(variant:progressHandler:) for multi-variant use.
    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        _ = try await loadModel(variant: "base.en", progressHandler: progressHandler)
    }

    func unloadModel() async {
        whisperKit = nil
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw TranscriptionEngineError.modelNotLoaded
        }

        let results = try await whisperKit.transcribe(audioPath: audioURL.path)

        let transcription = results
            .compactMap { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return transcription
    }
}
