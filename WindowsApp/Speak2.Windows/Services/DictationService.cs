using Speak2.Windows.Contracts;

namespace Speak2.Windows.Services;

public sealed class DictationService : IDictationService
{
    private readonly IAppPreferences _preferences;
    private readonly IWindowsHotkeyService _hotkeyService;

    public DictationService(IAppPreferences preferences, IWindowsHotkeyService hotkeyService)
    {
        _preferences = preferences;
        _hotkeyService = hotkeyService;

        _hotkeyService.OnKeyDown = HandleHotkeyDown;
        _hotkeyService.OnKeyUp = HandleHotkeyUp;
    }

    public Task StartAsync(CancellationToken cancellationToken = default)
    {
        _hotkeyService.Start();
        _preferences.SetBool("dictation-running", true);
        return Task.CompletedTask;
    }

    public void Stop()
    {
        _hotkeyService.Stop();
        _preferences.SetBool("dictation-running", false);
        _preferences.SetBool("dictation-hotkey-active", false);
    }

    private void HandleHotkeyDown()
    {
        _preferences.SetBool("dictation-hotkey-active", true);
        // Placeholder: DictationController.startRecordingIfNeeded()
    }

    private void HandleHotkeyUp()
    {
        _preferences.SetBool("dictation-hotkey-active", false);
        // Placeholder: DictationController.stopAndTranscribe()
    }
}
