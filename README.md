# Speak2

Local voice dictation for macOS. Hold the fn key to speak, release to transcribe. Works with any application.

100% on-device using [WhisperKit](https://github.com/argmaxinc/WhisperKit) - no cloud services, no data leaves your Mac.

## Requirements

- macOS 14.0 or later
- Apple Silicon Mac (M1/M2/M3)

## Installation

### Build from source

```bash
git clone https://github.com/zachswift615/speak2.git
cd speak2
swift build -c release
```

### Run

```bash
swift run
```

Or run the release binary directly:

```bash
.build/release/Speak2
```

## First Launch Setup

On first launch, a setup window will appear. You need to:

### 1. Grant Accessibility Permission

This is required for global fn key detection.

**Option A:** Add Speak2 directly
1. Open **System Settings > Privacy & Security > Accessibility**
2. Click the **+** button
3. Press **Cmd+Shift+G** and paste: `~/.build/release/Speak2` (or wherever you built it)
4. Select the Speak2 executable and enable it

**Option B:** Enable Terminal (easier for development)
1. Open **System Settings > Privacy & Security > Accessibility**
2. Find **Terminal** in the list and toggle it **ON**
3. This allows any app run from Terminal to use accessibility features

### 2. Grant Microphone Permission

Click "Grant" in the setup window and approve the macOS permission dialog.

### 3. Download Speech Model

Click "Download" to download the WhisperKit base.en model (~140MB).

**Note:** The progress bar doesn't update during download. The download takes 2-3 minutes depending on your connection. Just wait - it will complete and show a checkmark when done.

Once all three items show checkmarks, the setup window will indicate completion and you can close it.

## Usage

1. **Hold the fn key** - Recording starts (menu bar icon turns red)
2. **Speak** - Say what you want to type
3. **Release fn key** - Transcription happens (icon shows spinner), then text is pasted

The transcribed text is automatically pasted into whatever application has focus.

### Menu Bar

Speak2 runs as a menu bar app (no dock icon). Look for the microphone icon:

- **Gray mic** - Idle, ready to record
- **Red mic** - Recording in progress
- **Blue spinner** - Transcribing

Click the menu bar icon to access "Quit Speak2".

## How It Works

- **HotkeyManager** - Detects fn key press/release using CGEvent tap
- **AudioRecorder** - Captures microphone audio at 16kHz mono (optimal for Whisper)
- **WhisperTranscriber** - Runs WhisperKit on-device for speech-to-text
- **TextInjector** - Copies transcription to clipboard and simulates Cmd+V to paste

The Whisper model stays loaded in memory (~300MB RAM) for instant transcription.

## Tips

- Speak naturally with punctuation inflection - Whisper handles periods, commas, and question marks based on your tone
- Keep recordings under 30 seconds for best performance
- First transcription may be slightly slower as the model warms up

## Known Limitations

- Progress bar doesn't update during model download (just wait ~2-3 minutes)
- Uses clipboard for text injection (temporarily overwrites clipboard contents)
- fn key detection requires Accessibility permission
- Only tested on Apple Silicon Macs

## Tech Stack

- Swift + SwiftUI
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) - Apple's optimized Whisper implementation
- AVFoundation for audio capture
- CGEvent for global hotkey detection

## License

MIT
