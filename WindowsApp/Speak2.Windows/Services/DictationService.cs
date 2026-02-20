using Speak2.Windows.Contracts;

namespace Speak2.Windows.Services;

public sealed class DictationService : IDictationService
{
    public Task StartAsync(CancellationToken cancellationToken = default)
    {
        // Stub where HotkeyManagerWindows + engine startup is wired.
        ApplicationDataStorage.SetBool("dictation-running", true);
        return Task.CompletedTask;
    }

    public void Stop()
    {
        ApplicationDataStorage.SetBool("dictation-running", false);
    }
}
