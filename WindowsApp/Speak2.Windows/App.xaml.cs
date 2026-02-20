using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Speak2.Windows.Contracts;
using Speak2.Windows.Infrastructure;
using Speak2.Windows.Services;
using Speak2.Windows.Views;

namespace Speak2.Windows;

public partial class App : Application
{
    private IHost? _host;
    private ShellWindow? _shellWindow;
    public static XamlRoot? MainXamlRoot { get; private set; }

    protected override async void OnLaunched(LaunchActivatedEventArgs args)
    {
        _host = Host.CreateDefaultBuilder()
            .ConfigureServices(services =>
            {
                services.AddSingleton<AppEventBus>();
                services.AddSingleton<ITrayMenuService, TrayMenuService>();
                services.AddSingleton<ISettingsNavigationService, SettingsNavigationService>();
                services.AddSingleton<ICapabilityService, CapabilityService>();
                services.AddSingleton<IFirstRunWorkflowService, FirstRunWorkflowService>();
                services.AddSingleton<IDictationService, DictationService>();
                services.AddSingleton<StartupOrchestrator>();
            })
            .Build();

        _shellWindow = new ShellWindow();
        _shellWindow.Activate();

        if (_shellWindow.Content is FrameworkElement root)
        {
            MainXamlRoot = root.XamlRoot;
        }

        var startup = _host.Services.GetRequiredService<StartupOrchestrator>();
        await startup.StartAsync();
    }
}
