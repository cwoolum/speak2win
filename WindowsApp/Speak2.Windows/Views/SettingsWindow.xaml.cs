using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Speak2.Windows.Contracts;

namespace Speak2.Windows.Views;

public sealed partial class SettingsWindow : Window
{
    private readonly IWindowsHotkeyService _hotkeyService;

    public SettingsWindow(IWindowsHotkeyService hotkeyService)
    {
        _hotkeyService = hotkeyService;
        InitializeComponent();
        RootNavigation.SelectionChanged += RootNavigationOnSelectionChanged;
        RootNavigation.SelectedItem = RootNavigation.MenuItems[0];
    }

    public void NavigateTo(string tab)
    {
        var item = RootNavigation.MenuItems
            .OfType<NavigationViewItem>()
            .FirstOrDefault(i => string.Equals(i.Tag as string, tab, StringComparison.OrdinalIgnoreCase));

        if (item is not null)
        {
            RootNavigation.SelectedItem = item;
            Navigate(item.Tag?.ToString());
        }
    }

    private void RootNavigationOnSelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        var tag = (args.SelectedItem as NavigationViewItem)?.Tag?.ToString();
        Navigate(tag);
    }

    private void Navigate(string? tab)
    {
        var text = tab switch
        {
            "setup" => "First-run setup checks microphone, input controls, and model download before dictation starts.",
            "models" => "Model management shell page.",
            "dictionary" => "Dictionary management shell page.",
            "history" => "Transcription history shell page.",
            _ => BuildGeneralPageText()
        };

        ContentFrame.Content = new TextBlock
        {
            Text = text,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(24)
        };
    }

    private string BuildGeneralPageText()
    {
        var descriptor = _hotkeyService.GetBindingDescriptor(_hotkeyService.CurrentOption);
        var warningText = string.IsNullOrWhiteSpace(descriptor.WarningMessage)
            ? "No compatibility warning for this key mapping on your current platform."
            : $"Warning: {descriptor.WarningMessage}";

        return $"General settings shell page.\n\nRequested hotkey: {descriptor.RequestedDisplayName}\nWindows mapping: {descriptor.EffectiveDisplayName}\n{warningText}";
    }
}
