import Foundation
import WhisperKit

actor WhisperTranscriber: TranscriptionEngine {
    private var whisperKit: WhisperKit?
    private var isLoading = false

    private static let modelVariant = "base.en"

    var isModelLoaded: Bool {
        whisperKit != nil
    }

    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        guard !isLoading && whisperKit == nil else { return }
        isLoading = true

        defer { isLoading = false }

        // Download model first with progress tracking
        let modelFolder = try await WhisperKit.download(
            variant: Self.modelVariant,
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
