import SwiftUI
import AVFoundation

struct SetupView: View {
    @ObservedObject var appState = AppState.shared
    @State private var isDownloadingModel = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Speak2 Setup")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Grant permissions and download the speech model to get started.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                PermissionRow(
                    title: "Accessibility",
                    description: "Required for global hotkey detection",
                    isGranted: appState.hasAccessibilityPermission,
                    action: requestAccessibility
                )

                PermissionRow(
                    title: "Microphone",
                    description: "Required for voice recording",
                    isGranted: appState.hasMicrophonePermission,
                    action: requestMicrophone
                )

                ModelDownloadRow(
                    isDownloaded: appState.isModelLoaded,
                    isDownloading: isDownloadingModel,
                    progress: appState.modelDownloadProgress,
                    action: downloadModel
                )
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            if appState.isSetupComplete {
                Text("Setup complete! Speak2 is ready.")
                    .foregroundColor(.green)
                    .fontWeight(.medium)

                Button("Close") {
                    NSApplication.shared.keyWindow?.close()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(32)
        .frame(width: 450)
        .onAppear {
            checkPermissions()
        }
    }

    private func checkPermissions() {
        appState.hasAccessibilityPermission = HotkeyManager.checkAccessibilityPermission()

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            appState.hasMicrophonePermission = true
        default:
            appState.hasMicrophonePermission = false
        }
    }

    private func requestAccessibility() {
        HotkeyManager.requestAccessibilityPermission()
        // Poll for permission since there's no callback
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if HotkeyManager.checkAccessibilityPermission() {
                appState.hasAccessibilityPermission = true
                timer.invalidate()
            }
        }
    }

    private func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                appState.hasMicrophonePermission = granted
            }
        }
    }

    private func downloadModel() {
        isDownloadingModel = true

        Task {
            do {
                let transcriber = WhisperTranscriber()
                try await transcriber.loadModel { progress in
                    Task { @MainActor in
                        appState.modelDownloadProgress = progress
                    }
                }
                await MainActor.run {
                    appState.isModelLoaded = true
                    isDownloadingModel = false
                }
            } catch {
                await MainActor.run {
                    appState.lastError = error.localizedDescription
                    isDownloadingModel = false
                }
            }
        }
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button("Grant") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct ModelDownloadRow: View {
    let isDownloaded: Bool
    let isDownloading: Bool
    let progress: Double
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Speech Model")
                    .fontWeight(.medium)
                Text("~140MB download, runs locally")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isDownloaded {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else if isDownloading {
                ProgressView(value: progress)
                    .frame(width: 100)
            } else {
                Button("Download") {
                    action()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
