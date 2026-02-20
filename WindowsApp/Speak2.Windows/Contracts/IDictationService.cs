namespace Speak2.Windows.Contracts;

public interface IDictationService
{
    Task StartAsync(CancellationToken cancellationToken = default);
    void Stop();
}
