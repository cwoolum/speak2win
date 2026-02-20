using Windows.Devices.Enumeration;
using Windows.Media.Capture;
using Windows.Security.Authorization.AppCapabilityAccess;
using Microsoft.UI.Xaml.Controls;
using Speak2.Windows.Contracts;
using Speak2.Windows.Models;

namespace Speak2.Windows.Services;

public sealed class CapabilityService : ICapabilityService
{
    private const string FirstRunKey = "is-first-run";

    public async Task<CapabilitySnapshot> EvaluateAsync(CancellationToken cancellationToken = default)
    {
        var hasMicrophone = await CheckMicrophoneAccessAsync();
        var hasInput = CheckInputControlAccess();
        var hasModel = ApplicationDataStorage.HasDownloadedModel();
        var isFirstRun = ApplicationDataStorage.GetBool(FirstRunKey, true);

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
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> RequestInputControlPromptAsync()
    {
        var dialog = new ContentDialog
        {
            Title = "Enable keyboard/input access",
            Content = "Speak2 needs keyboard and input control access for global push-to-talk and text injection. Open the Windows Settings instructions now?",
            PrimaryButtonText = "Open instructions",
            CloseButtonText = "Not now",
            DefaultButton = ContentDialogButton.Primary,
            XamlRoot = App.MainXamlRoot
        };

        var result = await dialog.ShowAsync();
        if (result == ContentDialogResult.Primary)
        {
            _ = Launcher.OpenUriAsync(new Uri("ms-settings:privacy"));
        }

        return CheckInputControlAccess();
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

    private static bool CheckInputControlAccess()
    {
        // Placeholder capability gate for global hotkeys/text injection.
        // Equivalent to macOS accessibility permission checks in AppDelegate.
        return ApplicationDataStorage.GetBool("input-access-granted", false);
    }
}

internal static class ApplicationDataStorage
{
    private static readonly Dictionary<string, object> Data = new();

    public static bool GetBool(string key, bool fallback)
        => Data.TryGetValue(key, out var value) && value is bool parsed ? parsed : fallback;

    public static void SetBool(string key, bool value)
        => Data[key] = value;

    public static bool HasDownloadedModel()
        => GetBool("has-downloaded-model", false);
}

internal static class Launcher
{
    public static Task OpenUriAsync(Uri uri)
        => Windows.System.Launcher.LaunchUriAsync(uri).AsTask();
}
