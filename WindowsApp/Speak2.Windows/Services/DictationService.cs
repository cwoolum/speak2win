using Speak2.Windows.Contracts;

namespace Speak2.Windows.Services;

public sealed class DictationService : IDictationService
{
    private readonly IAppPreferences _preferences;

    public DictationService(IAppPreferences preferences)
    {
        _preferences = preferences;
    }

    public Task StartAsync(CancellationToken cancellationToken = default)
    {
        // Stub where HotkeyManagerWindows + transcription engine startup is wired.
        _preferences.SetBool("dictation-running", true);
        return Task.CompletedTask;
    }

    public void Stop()
    {
        _preferences.SetBool("dictation-running", false);
    }
}
