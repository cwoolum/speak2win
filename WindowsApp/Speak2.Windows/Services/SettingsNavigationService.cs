using Microsoft.UI.Xaml;
using Speak2.Windows.Contracts;
using Speak2.Windows.Views;

namespace Speak2.Windows.Services;

public sealed class SettingsNavigationService : ISettingsNavigationService
{
    private SettingsWindow? _window;

    public void OpenSettings(string? tab = null)
    {
        _window ??= new SettingsWindow();
        _window.Activate();

        if (!string.IsNullOrWhiteSpace(tab))
        {
            _window.NavigateTo(tab);
        }
    }
}
