using System.Runtime.InteropServices;
using Speak2.Windows.Contracts;
using Speak2.Windows.Models;

namespace Speak2.Windows.Services;

public sealed class WindowsHotkeyService : IWindowsHotkeyService
{
    private readonly IAppPreferences _preferences;
    private readonly object _stateLock = new();

    private const string HotkeyPreferenceKey = "hotkey-option";

    private CancellationTokenSource? _loopCancellation;
    private Task? _loopTask;
    private bool _isHotkeyActive;
    private HotkeyBindingDescriptor _binding;

    public WindowsHotkeyService(IAppPreferences preferences)
    {
        _preferences = preferences;
        CurrentOption = HotkeyOptionExtensions.Parse(_preferences.GetString(HotkeyPreferenceKey, "fn"));
        _binding = BuildDescriptor(CurrentOption);
    }

    public Action? OnKeyDown { get; set; }
    public Action? OnKeyUp { get; set; }
    public HotkeyOption CurrentOption { get; private set; }

    public HotkeyBindingDescriptor GetBindingDescriptor(HotkeyOption option) => BuildDescriptor(option);

    public void UpdateHotkey(HotkeyOption option)
    {
        lock (_stateLock)
        {
            CurrentOption = option;
            _binding = BuildDescriptor(option);
            _preferences.SetString(HotkeyPreferenceKey, option.ToPreferenceValue());
        }
    }

    public void Start()
    {
        if (_loopTask is { IsCompleted: false })
        {
            return;
        }

        _loopCancellation = new CancellationTokenSource();
        _loopTask = Task.Run(() => PollLoopAsync(_loopCancellation.Token));
    }

    public void Stop()
    {
        _loopCancellation?.Cancel();

        try
        {
            _loopTask?.Wait(TimeSpan.FromMilliseconds(250));
        }
        catch (AggregateException)
        {
            // Poll loop cancellation path.
        }

        lock (_stateLock)
        {
            if (_isHotkeyActive)
            {
                _isHotkeyActive = false;
                OnKeyUp?.Invoke();
            }
        }
    }

    private async Task PollLoopAsync(CancellationToken cancellationToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(16));

        while (await timer.WaitForNextTickAsync(cancellationToken))
        {
            HotkeyBindingDescriptor binding;
            lock (_stateLock)
            {
                binding = _binding;
            }

            var pressed = binding.IsPressed();
            var keyDownCallback = default(Action);
            var keyUpCallback = default(Action);

            lock (_stateLock)
            {
                if (pressed && !_isHotkeyActive)
                {
                    _isHotkeyActive = true;
                    keyDownCallback = OnKeyDown;
                }
                else if (!pressed && _isHotkeyActive)
                {
                    _isHotkeyActive = false;
                    keyUpCallback = OnKeyUp;
                }
            }

            keyDownCallback?.Invoke();
            keyUpCallback?.Invoke();
        }
    }

    private static HotkeyBindingDescriptor BuildDescriptor(HotkeyOption option)
    {
        return option switch
        {
            HotkeyOption.FnKey => new HotkeyBindingDescriptor(
                option,
                "Fn (hold)",
                "Right Alt (hold)",
                "Fn cannot be observed through Windows packaged-app APIs. Speak2 uses Right Alt as a fallback.",
                () => IsDown(VirtualKey.RightMenu)),

            HotkeyOption.RightOption => new HotkeyBindingDescriptor(
                option,
                "Right Option (hold)",
                "Right Alt (hold)",
                null,
                () => IsDown(VirtualKey.RightMenu)),

            HotkeyOption.RightCommand => new HotkeyBindingDescriptor(
                option,
                "Right Command (hold)",
                "Right Windows (hold)",
                "Command maps to the Windows key on PC keyboards.",
                () => IsDown(VirtualKey.RightWindows)),

            HotkeyOption.HyperKey => new HotkeyBindingDescriptor(
                option,
                "Hyper Key (hold) – Ctrl+Opt+Cmd+Shift",
                "Hyper Key (hold) – Ctrl+Alt+Win+Shift",
                "Option and Command are mapped to Alt and Windows on PC keyboards.",
                () => IsDown(VirtualKey.Control)
                    && IsAltDown()
                    && IsWindowsDown()
                    && IsShiftDown()),

            HotkeyOption.CtrlOptionSpace => new HotkeyBindingDescriptor(
                option,
                "Ctrl+Option+Space (hold)",
                "Ctrl+Alt+Space (hold)",
                "Option maps to Alt on PC keyboards.",
                () => IsDown(VirtualKey.Control)
                    && IsAltDown()
                    && IsDown(VirtualKey.Space)),

            _ => throw new ArgumentOutOfRangeException(nameof(option), option, null)
        };
    }

    private static bool IsShiftDown() => IsDown(VirtualKey.LeftShift) || IsDown(VirtualKey.RightShift);
    private static bool IsAltDown() => IsDown(VirtualKey.LeftMenu) || IsDown(VirtualKey.RightMenu);
    private static bool IsWindowsDown() => IsDown(VirtualKey.LeftWindows) || IsDown(VirtualKey.RightWindows);

    private static bool IsDown(VirtualKey key)
    {
        var state = GetAsyncKeyState((int)key);
        return (state & 0x8000) != 0;
    }

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int virtualKey);

    private enum VirtualKey
    {
        Space = 0x20,
        LeftShift = 0xA0,
        RightShift = 0xA1,
        Control = 0x11,
        LeftMenu = 0xA4,
        RightMenu = 0xA5,
        LeftWindows = 0x5B,
        RightWindows = 0x5C
    }
}
