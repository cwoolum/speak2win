using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace Speak2.Windows.Views;

public sealed partial class SettingsWindow : Window
{
    public SettingsWindow()
    {
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
            _ => "General settings shell page."
        };

        ContentFrame.Content = new TextBlock
        {
            Text = text,
            TextWrapping = TextWrapping.Wrap,
            Margin = new Thickness(24)
        };
    }
}
