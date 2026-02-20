# Windows app shell mapping (WinUI 3 packaged)

This shell maps the current `Speak2App.swift` + `AppDelegate` responsibilities to Windows-oriented startup services.

## Lifecycle mapping

1. **Startup + background behavior**
   - `StartupOrchestrator.StartAsync` replaces `applicationDidFinishLaunching`.
   - `TrayMenuService` provides status-area app behavior (tray icon + context menu) to mirror the macOS status bar flow.
   - `StartupOrchestrator.Stop()` is the symmetric shutdown entrypoint for dictation teardown.

2. **Settings window navigation**
   - `SettingsNavigationService` owns one reusable `SettingsWindow` instance and supports direct tab routing (`OpenSettings(tab)`).
   - `SettingsWindow` exposes Setup/General/Models/Dictionary/History sections to match unified settings semantics.

3. **First-run setup workflow**
   - `FirstRunWorkflowService` runs only on first launch and opens setup.
   - It requests microphone access prompt and the input-control onboarding prompt.
   - The workflow publishes `CapabilityStateChanged` to trigger startup re-evaluation.

4. **NotificationCenter replacement**
   - `AppEventBus` replaces `NotificationCenter` with named events (`AppEvents`).
   - `StartupOrchestrator` subscribes to `OpenSetupWindow`, `OpenSettingsWindow`, `OpenSettingsTab`, and `CapabilityStateChanged`.

## Capability gating

- `CapabilityService.EvaluateAsync` computes a `CapabilitySnapshot` containing:
  - microphone access
  - keyboard/input control access
  - model availability
  - first-run flag
- `StartupOrchestrator.EvaluateAndStartDictationAsync` gates dictation startup on `snapshot.IsReadyForDictation`.
- If checks fail, the orchestrator routes to Setup instead of starting dictation.

## Windows capability implementation details

- `Package.appxmanifest` declares:
  - `DeviceCapability Name="microphone"`
  - `uap5:Capability Name="inputInjectionBrokered"`
- `CapabilityService` checks microphone access via `AppCapability` (fallback to `DeviceAccessInformation`).
- Input-control permission is represented with an explicit first-run prompt + persisted gate state so dictation cannot start until acknowledged/granted.
