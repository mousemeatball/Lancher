#if canImport(Carbon)
import Carbon

/// Default summon shortcut: ⌥Space (Option-Space).
public enum HotKeyDefaults {
    public static let summonKeyCode = UInt32(kVK_Space)
    public static let summonModifiers = UInt32(optionKey)
}

/// Registers a system-wide hotkey via the Carbon Event Manager.
///
/// Unlike an `NSEvent` global monitor, `RegisterEventHotKey` intercepts the key combination
/// and requires no Accessibility permission — ideal for summoning the launcher from anywhere.
/// Hotkey events are delivered on the main run loop, so the callback hops to the main actor.
@MainActor
public final class GlobalHotKey {
    nonisolated(unsafe) private var hotKeyRef: EventHotKeyRef?
    nonisolated(unsafe) private var handlerRef: EventHandlerRef?
    private let onPressed: @MainActor () -> Void

    public init?(
        keyCode: UInt32 = HotKeyDefaults.summonKeyCode,
        modifiers: UInt32 = HotKeyDefaults.summonModifiers,
        onPressed: @escaping @MainActor () -> Void
    ) {
        self.onPressed = onPressed

        let target = GetApplicationEventTarget()
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let installStatus = InstallEventHandler(
            target,
            { _, _, userData -> OSStatus in
                guard let userData else { return noErr }
                MainActor.assumeIsolated {
                    let instance = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
                    instance.onPressed()
                }
                return noErr
            },
            1,
            &spec,
            Unmanaged.passUnretained(self).toOpaque(),
            &handlerRef
        )
        guard installStatus == noErr else { return nil }

        let hotKeyID = EventHotKeyID(signature: OSType(0x4C4E_4348), id: 1) // 'LNCH'
        let registerStatus = RegisterEventHotKey(
            keyCode, modifiers, hotKeyID, target, 0, &hotKeyRef
        )
        guard registerStatus == noErr else {
            if let handlerRef { RemoveEventHandler(handlerRef) }
            return nil
        }
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}
#endif
