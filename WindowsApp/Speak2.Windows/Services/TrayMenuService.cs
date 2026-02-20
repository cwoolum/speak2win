using System.Windows.Forms;
using Speak2.Windows.Contracts;
using Speak2.Windows.Infrastructure;

namespace Speak2.Windows.Services;

/// <summary>
/// WinUI 3 still relies on a Win32 tray icon implementation for status-area apps.
/// </summary>
public sealed class TrayMenuService : ITrayMenuService, IDisposable
{
    private readonly AppEventBus _eventBus;
    private NotifyIcon? _notifyIcon;

    public TrayMenuService(AppEventBus eventBus)
    {
        _eventBus = eventBus;
    }

    public void Initialize()
    {
        if (_notifyIcon is not null)
        {
            return;
        }

        var contextMenu = new ContextMenuStrip();
        contextMenu.Items.Add("Settings...", null, (_, _) => _eventBus.Publish(AppEvents.OpenSettingsWindow));
        contextMenu.Items.Add("Dictionary", null, (_, _) => _eventBus.Publish(AppEvents.OpenSettingsTab, "dictionary"));
        contextMenu.Items.Add("History", null, (_, _) => _eventBus.Publish(AppEvents.OpenSettingsTab, "history"));
        contextMenu.Items.Add("First-run Setup", null, (_, _) => _eventBus.Publish(AppEvents.OpenSetupWindow));
        contextMenu.Items.Add("Exit", null, (_, _) => Environment.Exit(0));

        _notifyIcon = new NotifyIcon
        {
            Text = "Speak2",
            Icon = System.Drawing.SystemIcons.Application,
            Visible = true,
            ContextMenuStrip = contextMenu
        };

        _notifyIcon.DoubleClick += (_, _) => _eventBus.Publish(AppEvents.OpenSettingsWindow);
    }

    public void Dispose()
    {
        if (_notifyIcon is null)
        {
            return;
        }

        _notifyIcon.Visible = false;
        _notifyIcon.Dispose();
        _notifyIcon = null;
    }
}
