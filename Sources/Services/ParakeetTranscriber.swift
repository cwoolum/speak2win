import Foundation
import FluidAudio

actor ParakeetTranscriber: TranscriptionEngine {
    private var asrManager: AsrManager?
    private var isLoading = false

    var isModelLoaded: Bool {
        asrManager != nil
    }

    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        guard !isLoading && asrManager == nil else { return }
        isLoading = true

        defer { isLoading = false }

        // Download models with progress tracking
        // FluidAudio doesn't provide granular progress, so we estimate
        Task { @MainActor in
            progressHandler(0.1)
        }

        let models = try await AsrModels.downloadAndLoad(version: .v3)

        Task { @MainActor in
            progressHandler(0.8)
        }

        // Initialize ASR manager
        let manager = AsrManager(config: .default)
        try await manager.initialize(models: models)

        asrManager = manager

        Task { @MainActor in
            progressHandler(1.0)
        }
    }

    func unloadModel() async {
        asrManager = nil
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let asrManager = asrManager else {
            throw TranscriptionEngineError.modelNotLoaded
        }

        // FluidAudio expects 16kHz mono PCM samples
        let samples = try AudioConverter().resampleAudioFile(path: audioURL.path)
        let result = try await asrManager.transcribe(samples)

        return result.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
