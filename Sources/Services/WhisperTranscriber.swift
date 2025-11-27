import Foundation
import WhisperKit

actor WhisperTranscriber {
    private var whisperKit: WhisperKit?
    private var isLoading = false

    var isModelLoaded: Bool {
        whisperKit != nil
    }

    func loadModel(progressHandler: @escaping (Double) -> Void) async throws {
        guard !isLoading && whisperKit == nil else { return }
        isLoading = true

        defer { isLoading = false }

        // WhisperKit uses model names like "base.en", "tiny", etc.
        // The "openai_whisper-" prefix is not needed
        let config = WhisperKitConfig(
            model: "base.en",
            verbose: false,
            logLevel: .none,
            prewarm: true,
            load: true,
            download: true
        )

        whisperKit = try await WhisperKit(config)
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let whisperKit = whisperKit else {
            throw TranscriberError.modelNotLoaded
        }

        let results = try await whisperKit.transcribe(audioPath: audioURL.path)

        let transcription = results
            .compactMap { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return transcription
    }
}

enum TranscriberError: Error {
    case modelNotLoaded
    case transcriptionFailed
}
