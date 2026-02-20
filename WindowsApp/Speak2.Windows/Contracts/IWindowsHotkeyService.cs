using Speak2.Windows.Models;

namespace Speak2.Windows.Contracts;

public interface IWindowsHotkeyService
{
    Action? OnKeyDown { get; set; }
    Action? OnKeyUp { get; set; }
    HotkeyBindingDescriptor GetBindingDescriptor(HotkeyOption option);
    HotkeyOption CurrentOption { get; }
    void UpdateHotkey(HotkeyOption option);
    void Start();
    void Stop();
}
