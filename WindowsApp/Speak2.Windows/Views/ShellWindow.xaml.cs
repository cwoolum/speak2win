using Microsoft.UI.Windowing;
using Microsoft.UI.Xaml;
using WinRT.Interop;

namespace Speak2.Windows.Views;

public sealed partial class ShellWindow : Window
{
    public ShellWindow()
    {
        InitializeComponent();
        ConfigureSwitcherVisibility();
    }

    public void EnterBackgroundMode()
    {
        // Keep process alive for tray/background behavior while avoiding visible shell UI.
        Hide();
    }

    private void ConfigureSwitcherVisibility()
    {
        var hwnd = WindowNative.GetWindowHandle(this);
        var windowId = Microsoft.UI.Win32Interop.GetWindowIdFromWindow(hwnd);
        var appWindow = AppWindow.GetFromWindowId(windowId);
        appWindow.IsShownInSwitchers = false;
    }
}
