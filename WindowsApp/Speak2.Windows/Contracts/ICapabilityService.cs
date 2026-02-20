using Speak2.Windows.Models;

namespace Speak2.Windows.Contracts;

public interface ICapabilityService
{
    Task<CapabilitySnapshot> EvaluateAsync(CancellationToken cancellationToken = default);
    Task<bool> RequestMicrophonePromptAsync();
    Task<bool> RequestInputControlPromptAsync();
    void MarkFirstRunComplete();
    void SetInputAccessAcknowledged(bool value);
}
