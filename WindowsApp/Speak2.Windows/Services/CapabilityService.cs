using Windows.Devices.Enumeration;
using Windows.Media.Capture;
using Windows.Security.Authorization.AppCapabilityAccess;
using Windows.System;
using Microsoft.UI.Xaml.Controls;
using Speak2.Windows.Contracts;
using Speak2.Windows.Models;

namespace Speak2.Windows.Services;

public sealed class CapabilityService : ICapabilityService
{
    private readonly IAppPreferences _preferences;

    private const string FirstRunKey = "is-first-run";
    private const string HasDownloadedModelKey = "has-downloaded-model";
    private const string InputAccessGrantedKey = "input-access-granted";

    public CapabilityService(IAppPreferences preferences)
    {
        _preferences = preferences;
    }

    public async Task<CapabilitySnapshot> EvaluateAsync(CancellationToken cancellationToken = default)
    {
        var hasMicrophone = await CheckMicrophoneAccessAsync();
        var hasInput = await CheckInputControlAccessAsync();
        var hasModel = _preferences.GetBool(HasDownloadedModelKey);
        var isFirstRun = _preferences.GetBool(FirstRunKey, true);

        return new CapabilitySnapshot(hasMicrophone, hasInput, hasModel, isFirstRun);
    }

    public async Task<bool> RequestMicrophonePromptAsync()
    {
        try
        {
            using var capture = new MediaCapture();
            await capture.InitializeAsync(new MediaCaptureInitializationSettings
            {
                StreamingCaptureMode = StreamingCaptureMode.Audio
            });

            return await CheckMicrophoneAccessAsync();
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> RequestInputControlPromptAsync()
    {
        if (App.MainXamlRoot is null)
        {
            // If the UI root isn't available yet, we cannot show ContentDialog.
            return await CheckInputControlAccessAsync();
        }

        var dialog = new ContentDialog
        {
            Title = "Enable keyboard/input access",
            Content = "Speak2 needs keyboard/input control access for global push-to-talk and text insertion. Open Windows Settings and mark this step complete once enabled.",
            PrimaryButtonText = "Open settings",
            SecondaryButtonText = "I've enabled it",
            CloseButtonText = "Not now",
            DefaultButton = ContentDialogButton.Primary,
            XamlRoot = App.MainXamlRoot
        };

        var result = await dialog.ShowAsync();

        if (result == ContentDialogResult.Primary)
        {
            await Launcher.LaunchUriAsync(new Uri("ms-settings:privacy"));
            return false;
        }

        if (result == ContentDialogResult.Secondary)
        {
            _preferences.SetBool(InputAccessGrantedKey, true);
        }

        return await CheckInputControlAccessAsync();
    }

    public void MarkFirstRunComplete()
    {
        _preferences.SetBool(FirstRunKey, false);
    }

    public void SetInputAccessAcknowledged(bool value)
    {
        _preferences.SetBool(InputAccessGrantedKey, value);
    }

    private static async Task<bool> CheckMicrophoneAccessAsync()
    {
        try
        {
            var capability = AppCapability.Create("microphone");
            var status = await capability.CheckAccessAsync();
            return status == AppCapabilityAccessStatus.Allowed;
        }
        catch
        {
            var access = DeviceAccessInformation.CreateFromDeviceClass(DeviceClass.AudioCapture);
            return access.CurrentStatus == DeviceAccessStatus.Allowed;
        }
    }

    private async Task<bool> CheckInputControlAccessAsync()
    {
        try
        {
            var capability = AppCapability.Create("inputInjectionBrokered");
            var status = await capability.CheckAccessAsync();
            return status == AppCapabilityAccessStatus.Allowed || _preferences.GetBool(InputAccessGrantedKey);
        }
        catch
        {
            // Fallback to explicit onboarding acknowledgement.
            return _preferences.GetBool(InputAccessGrantedKey);
        }
    }
}
