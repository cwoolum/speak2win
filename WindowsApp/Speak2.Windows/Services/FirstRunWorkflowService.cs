using Speak2.Windows.Contracts;
using Speak2.Windows.Infrastructure;

namespace Speak2.Windows.Services;

public sealed class FirstRunWorkflowService : IFirstRunWorkflowService
{
    private readonly ICapabilityService _capabilityService;
    private readonly AppEventBus _eventBus;

    public FirstRunWorkflowService(ICapabilityService capabilityService, AppEventBus eventBus)
    {
        _capabilityService = capabilityService;
        _eventBus = eventBus;
    }

    public async Task RunAsync(CancellationToken cancellationToken = default)
    {
        var snapshot = await _capabilityService.EvaluateAsync(cancellationToken);

        if (!snapshot.IsFirstRun)
        {
            return;
        }

        _eventBus.Publish(AppEvents.OpenSetupWindow);

        if (!snapshot.HasMicrophoneAccess)
        {
            _ = await _capabilityService.RequestMicrophonePromptAsync();
        }

        if (!snapshot.HasInputAccess)
        {
            var granted = await _capabilityService.RequestInputControlPromptAsync();
            ApplicationDataStorage.SetBool("input-access-granted", granted);
        }

        ApplicationDataStorage.SetBool("is-first-run", false);
        _eventBus.Publish(AppEvents.CapabilityStateChanged);
    }
}
