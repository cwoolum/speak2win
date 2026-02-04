# Speak2

Local voice dictation for macOS. Hold the fn key (configurable) to speak, release to transcribe. Works with any application.

100% on-device using [WhisperKit](https://github.com/argmaxinc/WhisperKit) or [Parakeet](https://github.com/FluidInference/FluidAudio) - no cloud services, no data leaves your Mac.

## Speech Recognition Models

Speak2 supports multiple Whisper model sizes plus Parakeet for multilingual use:

| Model | Size | Languages | Best For |
|-------|------|-----------|----------|
| **Whisper tiny.en** | ~75 MB | English only | Fastest, lowest resource usage |
| **Whisper base.en** | ~140 MB | English only | Recommended balance of speed/accuracy |
| **Whisper small.en** | ~460 MB | English only | Better accuracy |
| **Whisper large-v3** | ~3 GB | 100+ languages | Best accuracy, multilingual |
| **Whisper large-v3 turbo** | ~954 MB | 100+ languages | Fast + accurate, multilingual |
| **Parakeet v3** | ~600 MB | 25 languages | Alternative multilingual option |

You can download multiple models and switch between them from the menu bar. Only one model is loaded at a time to conserve memory.

### Model Storage Location

By default, models are stored in `~/Library/Application Support/Speak2/Models/`. You can change this location in the setup window (click **Manage Models...** from the menu bar) if you prefer to store large models on an external drive or different location.

When changing the storage location, you'll be prompted to either move existing models to the new location or start fresh.

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

Choose a model and click "Download". For most users, **Whisper base.en** (~140MB) is recommended as a good balance of speed and accuracy.

See the [Speech Recognition Models](#speech-recognition-models) section above for all available options.

**Note:** Large models (large-v3, large-v3 turbo) will prompt for confirmation before downloading due to their size. Parakeet takes longer to load initially (~20-30 seconds) as it compiles the neural engine model. Subsequent loads are faster. The menu bar icon will show a spinning indicator while loading.

Once all three items show checkmarks, the setup window will indicate completion and you can close it.

## Usage

1. **Hold the fn key** - Recording starts (menu bar icon turns red)
2. **Speak** - Say what you want to type
3. **Release fn key** - Transcription happens (icon shows spinner), then text is pasted

The transcribed text is automatically pasted into whatever application text field has focus.

### Menu Bar

Speak2 runs as a menu bar app (no dock icon). Look for the microphone icon:

- **White/Black (depending on macOS theme)** - Idle, ready to record
- **Yellow spinning arrows** - Loading model
- **Red mic** - Recording in progress
- **Cyan spinner** - Transcribing

The menu shows a status line at the top indicating the current state (e.g., "Ready – Whisper (base.en)").

#### Switching Models
Click the menu bar icon and select **Model** to switch between downloaded models. Models not yet downloaded show a ↓ indicator - clicking them opens the setup window to download.

#### Manage Models
Click **Manage Models...** to open the setup window where you can download additional models or delete existing ones to free up disk space.

#### Choosing Hotkey
You can choose from several hotkey options. Sometimes external keyboards don't send the function key reliably. In that case, you can choose one of the other options from the menu.

#### Personal Dictionary

Speak2 includes a personal dictionary feature that helps improve transcription accuracy for names, technical terms, industry jargon, and unique spellings.

**Accessing the Dictionary:**
- Click the menu bar icon → **Dictionary** → **Manage Dictionary...** to open the full management window
- Click **Dictionary** → **Add Word...** for quick word addition

**Adding Words:**

Each dictionary entry can include:
| Field | Required | Description |
|-------|----------|-------------|
| Word | Yes | The correct spelling you want |
| Aliases | No | Common misspellings or mishearings (comma-separated) |
| Pronunciation | No | Phonetic hint for words spelled differently than pronounced |
| Category | No | Organization (Names, Technical, Medical, etc.) |
| Language | Yes | Which language this word belongs to (25 languages supported) |

**How It Works:**

When you speak, the transcription is post-processed using your dictionary:
1. **Alias matching** - Direct replacement of known misspellings (exact match, case-insensitive)
2. **Phonetic matching** - Multiple algorithms catch similar-sounding words:
   - **Soundex** - Traditional phonetic encoding
   - **Metaphone** - Better handling of English pronunciation rules
   - **Fuzzy matching** - Catches words with 70%+ similarity

**Using the Pronunciation Field:**

The pronunciation field helps when a word is spelled very differently from how it sounds. When set, phonetic matching uses the pronunciation hint instead of the word's spelling.

| Word | Pronunciation | Why |
|------|---------------|-----|
| Nguyen | "Win" | Vietnamese name pronounced differently than spelled |
| Siobhan | "Shivon" | Irish name with non-obvious pronunciation |
| GIF | "Jif" | If you prefer the soft G pronunciation |
| SQL | "Sequel" | Matches the spoken acronym |

**Examples:**

| Scenario | Word | Aliases | Pronunciation |
|----------|------|---------|---------------|
| Company name | Anthropic | Antropik, Anthropik | *(not needed - sounds like spelling)* |
| Technical term | Kubernetes | Cooper Netties, Kubernetties | *(not needed)* |
| Person's name | Siobhan | Shivon, Shavon | Shivon |
| Acronym | AWS | | Amazon Web Services |

For most words, you won't need the pronunciation field - phonetic matching will handle common mishearings automatically. Use it only when the spelling is very different from the sound.

**Right-Click Service:**

You can also add words directly from any application:
1. Select/highlight any text
2. Right-click → **Services** → **Add to Speak2 Dictionary**
3. Choose to add as a new word or as an alias to an existing word

> **Note:** The service may require logging out and back in to appear after first install.

**Import/Export:**

The dictionary can be exported to JSON and imported on another machine via the Manage Dictionary window.

#### Launch at Login
You can choose to have Speak2 launch at login. If selected, a checkmark will appear beside this option. Click it again to remove it from the list of start up apps. You'll see this when you choose the start up option:

<img width="352" height="98" alt="image" src="https://github.com/user-attachments/assets/b2480437-044f-402f-af8b-a4cc0b9d04b8" />

#### Quit Speak2
Click the menu bar icon and click "Quit Speak2".

## How It Works

- **HotkeyManager** - Detects hotkey press/release using CGEvent tap
- **AudioRecorder** - Captures microphone audio at 16kHz mono PCM
- **ModelManager** - Handles model downloading, loading, and switching
- **WhisperTranscriber** - Runs WhisperKit on-device for speech-to-text
- **ParakeetTranscriber** - Runs FluidAudio/Parakeet on-device for speech-to-text
- **DictionaryProcessor** - Post-processes transcription using personal dictionary (alias replacement + phonetic matching)
- **TextInjector** - Copies transcription to clipboard and simulates Cmd+V to paste

The selected model stays loaded in memory (~300-600MB RAM depending on model) for instant transcription.

## Tips

- Speak naturally with punctuation inflection - Whisper handles periods, commas, and question marks based on your tone
- Keep recordings under 30 seconds for best performance
- First transcription may be slightly slower as the model warms up
- Add frequently used names and technical terms to your personal dictionary for better accuracy
- Use aliases for words that are commonly misheard (e.g., add "Kubernetes" with alias "Cooper Netties")

## Troubleshooting

### Model won't load or keeps re-downloading

If you upgraded from an earlier version of Speak2, your models may have been stored at a legacy location (`~/Documents/huggingface`). The app attempts to migrate these automatically, but if you experience issues:

**Quick fix:**
1. Open the setup window (**Manage Models...** from menu bar)
2. Delete the affected model (trash icon)
3. Re-download it

**Manual cleanup (if needed):**
```bash
# Remove any orphaned model files at the old location
rm -rf ~/Documents/huggingface

# Remove incorrectly migrated files (if present)
rm -rf ~/Library/Application\ Support/Speak2/Models/huggingface

# Reset migration flag to trigger fresh migration on next launch
defaults delete com.zachswift.speak2 didAttemptLegacyMigrationV2
```

Then restart Speak2. If you had models at the legacy location, they'll be migrated to the correct path.

### Model shows as downloaded but won't transcribe

Try clicking on the model in the setup window to reload it. If that doesn't work, delete and re-download the model.

## Known Limitations

- Parakeet model takes ~20-30 seconds to load on first use (compiling neural engine model)
- Uses clipboard for text injection (briefly swaps clipboard contents, then attempts to restore them)
- fn key detection requires Accessibility permission
- Only tested on Apple Silicon Macs

## Tech Stack

- Swift + SwiftUI
- [WhisperKit](https://github.com/argmaxinc/WhisperKit) - Apple's optimized Whisper implementation
- [FluidAudio](https://github.com/FluidInference/FluidAudio) - Parakeet speech recognition for Apple Silicon
- AVFoundation for audio capture
- CGEvent for global hotkey detection

## License

MIT
