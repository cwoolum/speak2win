using Windows.Storage;
using Speak2.Windows.Contracts;

namespace Speak2.Windows.Services;

public sealed class AppPreferences : IAppPreferences
{
    private readonly ApplicationDataContainer _settings = ApplicationData.Current.LocalSettings;

    public bool GetBool(string key, bool fallback = false)
    {
        if (_settings.Values.TryGetValue(key, out var value) && value is bool parsed)
        {
            return parsed;
        }

        return fallback;
    }

    public void SetBool(string key, bool value)
    {
        _settings.Values[key] = value;
    }

    public string GetString(string key, string fallback = "")
    {
        if (_settings.Values.TryGetValue(key, out var value) && value is string parsed)
        {
            return parsed;
        }

        return fallback;
    }

    public void SetString(string key, string value)
    {
        _settings.Values[key] = value;
    }
}
