# Speak2

Local voice dictation for macOS. Hold the fn key (configurable) to speak, release to transcribe. Works with any application.

100% on-device using [WhisperKit](https://github.com/argmaxinc/WhisperKit) - no cloud services, no data leaves your Mac.

## Requirements

- macOS 14.0 or later
- Apple Silicon Mac (M1/M2/M3)

## Installation

### From DMG (recommended)
Download the latest .dmg from the [releases](https://github.com/zachswift615/speak2/releases) page and install.

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

#### DMG installs
<img width="456" height="356" alt="Screenshot 2025-12-01 at 2 13 06 PM" src="https://github.com/user-attachments/assets/fdd923ad-672a-4405-8db2-68e4529cd4d1" />

Click "Grant" next to Accessibility on the first launch window

<img width="466" height="183" alt="image" src="https://github.com/user-attachments/assets/28d9d0f9-25fb-4d7a-9396-1fad03426128" />

Then click Open System Settings

<img width="468" height="55" alt="image" src="https://github.com/user-attachments/assets/4b80e39e-0dec-4a19-8a6e-517c9fd4d578" />

Then find speak2 in the list and toggle the permission switch on and authenticate with password or fingerprint. If Speak2 is not in the list, click the `+` button and nagivate to your Applications directory where you dragged it to install, and Add Speak2 to the list of apps.

#### Building from source

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
Click "Grant" next to Microphone. And click "Allow" on the permission window that pops up. 

### 3. Download Speech Model

Click "Download" to download the WhisperKit base.en model (~140MB).

**Note:** The progress may appear stuck update during download. The download takes 1-3 minutes depending on your connection. Just wait - it will complete and show a checkmark when done.

<img width="460" height="441" alt="image" src="https://github.com/user-attachments/assets/c6b5a633-b178-403d-8bb1-5848634f5773" />

Once all three items show checkmarks, the setup window will indicate completion and you can close it.

## Usage

1. **Hold the fn key** - Recording starts (menu bar icon turns red)
2. **Speak** - Say what you want to type
3. **Release fn key** - Transcription happens (icon shows spinner), then text is pasted

The transcribed text is automatically pasted into whatever application text field has focus.

### Menu Bar

Speak2 runs as a menu bar app (no dock icon). Look for the microphone icon:

- **White/Black (depending on MacOS theme)** - Idle, ready to record
- **Red mic** - Recording in progress
- **Blue spinner** - Transcribing

#### Choosing hotkey 
You can choose from several hotkey options. Sometimes external keyboards don't send the function key reliably. In that case, you can choose one of the other options from the menu.

#### Launch at Login
You can choose to have Speak2 launch at login. If selected, a checkmark will appear beside this option. Click it again to remove it from the list of start up apps. You'll see this when you choose the start up option:

<img width="352" height="98" alt="image" src="https://github.com/user-attachments/assets/b2480437-044f-402f-af8b-a4cc0b9d04b8" />

#### Quit Speak2
Click the menu bar icon and click "Quit Speak2".

## How It Works

- **HotkeyManager** - Detects hot key key press/release using CGEvent tap
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
