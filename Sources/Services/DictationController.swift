import Foundation

@MainActor
class DictationController {
    private let hotkeyManager = HotkeyManager()
    private let audioRecorder = AudioRecorder()
    private let transcriber = WhisperTranscriber()
    private let textInjector = TextInjector()
    private let appState = AppState.shared

    private var currentRecordingURL: URL?

    func start() async throws {
        // Load model if not already loaded
        if !appState.isModelLoaded {
            try await transcriber.loadModel { [weak self] progress in
                Task { @MainActor in
                    self?.appState.modelDownloadProgress = progress
                }
            }
            appState.isModelLoaded = true
        }

        // Start hotkey monitoring
        guard hotkeyManager.start() else {
            throw DictationError.accessibilityDenied
        }

        hotkeyManager.onKeyDown = { [weak self] in
            self?.startRecording()
        }

        hotkeyManager.onKeyUp = { [weak self] in
            self?.stopRecordingAndTranscribe()
        }
    }

    private func startRecording() {
        guard appState.recordingState == .idle else { return }

        do {
            currentRecordingURL = try audioRecorder.startRecording()
            appState.recordingState = .recording
        } catch {
            appState.lastError = "Failed to start recording: \(error.localizedDescription)"
        }
    }

    private func stopRecordingAndTranscribe() {
        guard appState.recordingState == .recording else { return }

        guard let audioURL = audioRecorder.stopRecording() else {
            appState.recordingState = .idle
            return
        }

        appState.recordingState = .transcribing

        Task {
            do {
                let text = try await transcriber.transcribe(audioURL: audioURL)

                await MainActor.run {
                    if !text.isEmpty {
                        textInjector.inject(text: text)
                    }
                    appState.recordingState = .idle
                }
            } catch {
                await MainActor.run {
                    appState.lastError = "Transcription failed: \(error.localizedDescription)"
                    appState.recordingState = .idle
                }
            }

            audioRecorder.cleanup()
        }
    }

    func stop() {
        hotkeyManager.stop()
        if audioRecorder.isRecording {
            _ = audioRecorder.stopRecording()
        }
        audioRecorder.cleanup()
    }
}

enum DictationError: Error {
    case accessibilityDenied
    case microphoneDenied
    case modelNotLoaded
}
