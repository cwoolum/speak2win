using Speak2.Windows.Contracts;
using Speak2.Windows.Views;

namespace Speak2.Windows.Services;

public sealed class SettingsNavigationService : ISettingsNavigationService
{
    private readonly IWindowsHotkeyService _hotkeyService;
    private SettingsWindow? _window;

    public SettingsNavigationService(IWindowsHotkeyService hotkeyService)
    {
        _hotkeyService = hotkeyService;
    }

    public void OpenSettings(string? tab = null)
    {
        _window ??= new SettingsWindow(_hotkeyService);
        _window.Activate();

        if (!string.IsNullOrWhiteSpace(tab))
        {
            _window.NavigateTo(tab);
        }
    }
}
