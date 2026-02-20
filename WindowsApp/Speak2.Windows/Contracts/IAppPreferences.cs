namespace Speak2.Windows.Contracts;

public interface IAppPreferences
{
    bool GetBool(string key, bool fallback = false);
    void SetBool(string key, bool value);
}
