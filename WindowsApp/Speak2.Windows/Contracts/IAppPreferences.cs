namespace Speak2.Windows.Contracts;

public interface IAppPreferences
{
    bool GetBool(string key, bool fallback = false);
    void SetBool(string key, bool value);
    string GetString(string key, string fallback = "");
    void SetString(string key, string value);
}
