namespace Speak2.Windows.Models;

public sealed record CapabilitySnapshot(
    bool HasMicrophoneAccess,
    bool HasInputAccess,
    bool HasDownloadedModel,
    bool IsFirstRun)
{
    public bool IsReadyForDictation => HasMicrophoneAccess && HasInputAccess && HasDownloadedModel;
}
