import SwiftUI
import AVFoundation

struct SetupView: View {
    @ObservedObject var appState = AppState.shared
    @State private var downloadingModel: TranscriptionModel? = nil
    var modelManager: ModelManager?

    var body: some View {
        VStack(spacing: 24) {
            Text("Speak2 Setup")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Grant permissions and download a speech model to get started.")
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

                Divider()
                    .padding(.vertical, 4)

                Text("Speech Recognition Model")
                    .fontWeight(.medium)

                ForEach(TranscriptionModel.allCases, id: \.self) { model in
                    ModelSelectionRow(
                        model: model,
                        isSelected: appState.selectedModel == model,
                        isDownloaded: appState.downloadedModels.contains(model),
                        isDownloading: downloadingModel == model,
                        isCurrentlyLoaded: appState.currentlyLoadedModel == model,
                        progress: downloadingModel == model ? appState.modelDownloadProgress : 0,
                        onSelect: { selectModel(model) },
                        onDownload: { downloadModel(model) },
                        onDelete: { deleteModel(model) }
                    )
                }
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
        .frame(width: 480)
        .onAppear {
            checkPermissions()
            appState.refreshDownloadedModels()
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

    private func selectModel(_ model: TranscriptionModel) {
        appState.selectedModel = model
        TranscriptionModel.saved = model

        // If already downloaded, load it
        if appState.downloadedModels.contains(model) {
            downloadModel(model)
        }
    }

    private func downloadModel(_ model: TranscriptionModel) {
        guard let modelManager = modelManager else { return }
        downloadingModel = model

        Task {
            do {
                try await modelManager.loadModel(model) { progress in
                    Task { @MainActor in
                        appState.modelDownloadProgress = progress
                    }
                }
                await MainActor.run {
                    downloadingModel = nil
                }
            } catch {
                await MainActor.run {
                    appState.lastError = error.localizedDescription
                    downloadingModel = nil
                }
            }
        }
    }

    private func deleteModel(_ model: TranscriptionModel) {
        guard let modelManager = modelManager else { return }

        Task {
            do {
                try await modelManager.deleteModel(model)
            } catch {
                await MainActor.run {
                    appState.lastError = error.localizedDescription
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

struct ModelSelectionRow: View {
    let model: TranscriptionModel
    let isSelected: Bool
    let isDownloaded: Bool
    let isDownloading: Bool
    let isCurrentlyLoaded: Bool
    let progress: Double
    let onSelect: () -> Void
    let onDownload: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Radio button
            Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.title3)
                .onTapGesture {
                    if isDownloaded {
                        onSelect()
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(model.displayName)
                        .fontWeight(.medium)
                    if isCurrentlyLoaded {
                        Text("Active")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isDownloading {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(isDownloaded || progress >= 1.0 ? "Loading..." : "Downloading...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    ProgressView(value: progress)
                        .frame(width: 80)
                }
            } else if isDownloaded {
                HStack(spacing: 8) {
                    Text(model.estimatedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Delete model")
                }
            } else {
                Button("Download") {
                    onDownload()
                }
                .buttonStyle(.bordered)

                Text(model.estimatedSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isDownloaded && !isDownloading {
                onSelect()
            } else if !isDownloaded && !isDownloading {
                onDownload()
            }
        }
    }
}
