namespace Speak2.Windows.Models;

public enum HotkeyOption
{
    FnKey,
    RightOption,
    RightCommand,
    HyperKey,
    CtrlOptionSpace
}

public static class HotkeyOptionExtensions
{
    public static HotkeyOption Parse(string? raw)
    {
        return raw?.Trim().ToLowerInvariant() switch
        {
            "fn" or "fnkey" => HotkeyOption.FnKey,
            "rightoption" => HotkeyOption.RightOption,
            "rightcommand" => HotkeyOption.RightCommand,
            "hyperkey" => HotkeyOption.HyperKey,
            "ctrloptionspace" => HotkeyOption.CtrlOptionSpace,
            _ => HotkeyOption.FnKey
        };
    }

    public static string ToPreferenceValue(this HotkeyOption option)
    {
        return option switch
        {
            HotkeyOption.FnKey => "fn",
            HotkeyOption.RightOption => "rightOption",
            HotkeyOption.RightCommand => "rightCommand",
            HotkeyOption.HyperKey => "hyperKey",
            HotkeyOption.CtrlOptionSpace => "ctrlOptionSpace",
            _ => "fn"
        };
    }

    public static string DisplayName(this HotkeyOption option)
    {
        return option switch
        {
            HotkeyOption.FnKey => "Fn (hold)",
            HotkeyOption.RightOption => "Right Alt (hold)",
            HotkeyOption.RightCommand => "Right Windows (hold)",
            HotkeyOption.HyperKey => "Hyper Key (hold) – Ctrl+Alt+Win+Shift",
            HotkeyOption.CtrlOptionSpace => "Ctrl+Alt+Space (hold)",
            _ => "Fn (hold)"
        };
    }
}
