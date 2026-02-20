# Windows app shell mapping (WinUI 3 packaged)

This shell maps the current `Speak2App.swift` + `AppDelegate` responsibilities to Windows-oriented startup services.

## Lifecycle mapping

1. **Startup + background behavior**
   - `StartupOrchestrator.StartAsync` replaces `applicationDidFinishLaunching`.
   - `ShellWindow` is bootstrapped only to establish XAML root/context, then moved into background mode (hidden from switchers and hidden from desktop UI).
   - `TrayMenuService` provides status-area app behavior (tray icon + context menu) to mirror the macOS status bar flow.
   - `StartupOrchestrator.Stop()` is the symmetric shutdown entrypoint for dictation teardown.

2. **Settings window navigation**
   - `SettingsNavigationService` owns one reusable `SettingsWindow` instance and supports direct tab routing (`OpenSettings(tab)`).
   - `SettingsWindow` exposes Setup/General/Models/Dictionary/History sections to match unified settings semantics.

3. **First-run setup workflow**
   - `FirstRunWorkflowService` runs only on first launch and opens setup.
   - It requests microphone access prompt and the input-control onboarding prompt.
   - First-run and input acknowledgement state are persisted in local app settings (`IAppPreferences`).
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
- `CapabilityService` checks:
  - microphone via `AppCapability("microphone")` with fallback to `DeviceAccessInformation`
  - input controls via `AppCapability("inputInjectionBrokered")` with fallback to persisted onboarding acknowledgement
- `RequestInputControlPromptAsync` opens Windows privacy settings and requires explicit user acknowledgement before dictation startup is allowed.
