using Speak2.Windows.Contracts;
using Speak2.Windows.Infrastructure;

namespace Speak2.Windows.Services;

/// <summary>
/// Maps responsibilities from Speak2App.swift/AppDelegate to Windows startup services.
/// </summary>
public sealed class StartupOrchestrator
{
    private readonly ITrayMenuService _trayMenuService;
    private readonly ISettingsNavigationService _settingsNavigationService;
    private readonly IFirstRunWorkflowService _firstRunWorkflowService;
    private readonly ICapabilityService _capabilityService;
    private readonly IDictationService _dictationService;
    private readonly AppEventBus _eventBus;

    public StartupOrchestrator(
        ITrayMenuService trayMenuService,
        ISettingsNavigationService settingsNavigationService,
        IFirstRunWorkflowService firstRunWorkflowService,
        ICapabilityService capabilityService,
        IDictationService dictationService,
        AppEventBus eventBus)
    {
        _trayMenuService = trayMenuService;
        _settingsNavigationService = settingsNavigationService;
        _firstRunWorkflowService = firstRunWorkflowService;
        _capabilityService = capabilityService;
        _dictationService = dictationService;
        _eventBus = eventBus;
    }

    public async Task StartAsync(CancellationToken cancellationToken = default)
    {
        WireEventBus();
        _trayMenuService.Initialize();

        await _firstRunWorkflowService.RunAsync(cancellationToken);
        await EvaluateAndStartDictationAsync(cancellationToken);
    }

    public void Stop() => _dictationService.Stop();

    private void WireEventBus()
    {
        _eventBus.Subscribe(AppEvents.OpenSettingsWindow, _ => _settingsNavigationService.OpenSettings());
        _eventBus.Subscribe(AppEvents.OpenSettingsTab, tab => _settingsNavigationService.OpenSettings(tab as string));
        _eventBus.Subscribe(AppEvents.OpenSetupWindow, _ => _settingsNavigationService.OpenSettings("setup"));
        _eventBus.Subscribe(AppEvents.CapabilityStateChanged, async _ => await EvaluateAndStartDictationAsync());
    }

    private async Task EvaluateAndStartDictationAsync(CancellationToken cancellationToken = default)
    {
        var snapshot = await _capabilityService.EvaluateAsync(cancellationToken);
        if (!snapshot.IsReadyForDictation)
        {
            _settingsNavigationService.OpenSettings("setup");
            return;
        }

        await _dictationService.StartAsync(cancellationToken);
    }
}
