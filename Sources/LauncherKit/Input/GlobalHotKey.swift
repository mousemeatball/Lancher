#if canImport(Carbon)
import Carbon.HIToolbox
import AppKit

/// Registers a system-wide hotkey via Carbon's `RegisterEventHotKey`. Unlike a `CGEventTap`, this
/// needs **no Accessibility permission**, which keeps first-run friction low.
///
/// Defaults to ⌥Space. The fire callback is invoked on the main run loop. `init?` returns `nil` if
/// registration fails (e.g. the combo is already taken), so the caller can fall back to the menu.
public final class GlobalHotKey {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let callback: () -> Void

    /// Four-char code 'LNCH', identifying our hotkey to Carbon.
    private static let signature: OSType = 0x4C_4E_43_48

    public init?(
        keyCode: UInt32 = UInt32(kVK_Space),
        modifiers: UInt32 = UInt32(optionKey),
        handler: @escaping () -> Void
    ) {
        self.callback = handler

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        var handlerRef: EventHandlerRef?
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetEventDispatcherTarget(),
            Self.trampoline,
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )
        guard installStatus == noErr else { return nil }
        self.eventHandler = handlerRef

        var keyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: 1)
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &keyRef
        )
        guard registerStatus == noErr else {
            if let handlerRef { RemoveEventHandler(handlerRef) }
            return nil
        }
        self.hotKeyRef = keyRef
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    /// Bare C trampoline (captures nothing, so it bridges to a function pointer); recovers `self`
    /// from the `userData` pointer and fires the stored callback.
    private static let trampoline: EventHandlerUPP = { _, _, userData in
        guard let userData else { return noErr }
        Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue().callback()
        return noErr
    }
}
#endif
