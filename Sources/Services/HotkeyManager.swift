import AppKit
import Carbon.HIToolbox

class HotkeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isHotkeyActive = false
    private var hotkeyOption: HotkeyOption

    // Keycodes for distinguishing left/right modifier keys
    private let kVK_RightOption: Int64 = 0x3D
    private let kVK_RightCommand: Int64 = 0x36
    private let kVK_Space: Int64 = 0x31

    var onKeyDown: (() -> Void)?
    var onKeyUp: (() -> Void)?

    init(hotkeyOption: HotkeyOption = HotkeyOption.saved) {
        self.hotkeyOption = hotkeyOption
    }

    func start() -> Bool {
        // Check accessibility permissions
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            return false
        }

        // Create event tap for flag changes and key events
        var eventMask = (1 << CGEventType.flagsChanged.rawValue)

        // For ctrlOptionSpace, we also need to listen for key down/up
        if hotkeyOption == .ctrlOptionSpace {
            eventMask |= (1 << CGEventType.keyDown.rawValue)
            eventMask |= (1 << CGEventType.keyUp.rawValue)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        var hotkeyPressed = false

        switch hotkeyOption {
        case .fnKey:
            if type == .flagsChanged {
                hotkeyPressed = flags.contains(.maskSecondaryFn)
            }

        case .rightOption:
            if type == .flagsChanged {
                // Check if Option is pressed AND it's the right Option key
                hotkeyPressed = flags.contains(.maskAlternate) && keyCode == kVK_RightOption
                // Keep active while right option is held
                if !hotkeyPressed && isHotkeyActive && flags.contains(.maskAlternate) {
                    hotkeyPressed = true
                }
            }

        case .rightCommand:
            if type == .flagsChanged {
                // Check if Command is pressed AND it's the right Command key
                hotkeyPressed = flags.contains(.maskCommand) && keyCode == kVK_RightCommand
                // Keep active while right command is held
                if !hotkeyPressed && isHotkeyActive && flags.contains(.maskCommand) {
                    hotkeyPressed = true
                }
            }

        case .hyperKey:
            if type == .flagsChanged {
                // Hyper key = Ctrl + Option + Command + Shift all pressed
                let hyperFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand, .maskShift]
                hotkeyPressed = flags.contains(hyperFlags)
            }

        case .ctrlOptionSpace:
            // Need Ctrl + Option held, then Space pressed
            let hasCtrlOption = flags.contains(.maskControl) && flags.contains(.maskAlternate)

            if type == .keyDown && keyCode == kVK_Space && hasCtrlOption {
                hotkeyPressed = true
            } else if type == .keyUp && keyCode == kVK_Space && isHotkeyActive {
                hotkeyPressed = false
            } else if isHotkeyActive && hasCtrlOption {
                // Keep active while modifiers held and we're in active state
                hotkeyPressed = true
            }
        }

        // Handle state transitions
        if hotkeyPressed && !isHotkeyActive {
            isHotkeyActive = true
            DispatchQueue.main.async { [weak self] in
                self?.onKeyDown?()
            }
        } else if !hotkeyPressed && isHotkeyActive {
            isHotkeyActive = false
            DispatchQueue.main.async { [weak self] in
                self?.onKeyUp?()
            }
        }

        return Unmanaged.passRetained(event)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isHotkeyActive = false
    }

    func updateHotkey(_ option: HotkeyOption) {
        stop()
        hotkeyOption = option
        HotkeyOption.saved = option
        _ = start()
    }

    static func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }

    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
