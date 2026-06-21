import Foundation

/// A selectable global-shortcut preset (Carbon key code + modifier mask). A full key recorder is
/// future work; presets cover the common, non-conflicting choices.
public struct HotKeyCombo: Identifiable, Sendable, Hashable {
    public let name: String
    public let keyCode: UInt32
    public let modifiers: UInt32

    public var id: String { "\(keyCode)-\(modifiers)" }

    public init(name: String, keyCode: UInt32, modifiers: UInt32) {
        self.name = name
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    // Carbon modifier masks: cmd=256, shift=512, option=2048, control=4096.
    public static let presets: [HotKeyCombo] = [
        .init(name: "⌥ Space", keyCode: 49, modifiers: 2048),
        .init(name: "⌃ Space", keyCode: 49, modifiers: 4096),
        .init(name: "⌘⌥ Space", keyCode: 49, modifiers: 2048 + 256),
        .init(name: "⌥ A", keyCode: 0, modifiers: 2048),
        .init(name: "F1", keyCode: 122, modifiers: 0),
    ]
}
