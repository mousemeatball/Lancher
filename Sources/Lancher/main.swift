import AppKit
import LauncherKit

// Lancher is a menu-bar (agent) app. When run via `swift run` there is no Info.plist to declare
// `LSUIElement`, so set the activation policy explicitly at runtime; the packaged `.app` declares
// `LSUIElement` in its Info.plist for the same effect.
let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.accessory)
application.run()
