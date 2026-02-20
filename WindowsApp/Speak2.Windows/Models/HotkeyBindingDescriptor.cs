namespace Speak2.Windows.Models;

public sealed record HotkeyBindingDescriptor(
    HotkeyOption RequestedOption,
    string RequestedDisplayName,
    string EffectiveDisplayName,
    string? WarningMessage,
    Func<bool> IsPressed
);
