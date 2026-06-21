#if canImport(AppKit)
import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Applies an `IconStyle` treatment to an app icon. Results are cached (icons are redrawn often).
/// Note: Dark/Light/Tinted/Clear-Colored are *approximations* — true system icon variants require
/// per-app assets the apps must ship; here we recolor/composite generically.
enum IconRenderer {
    // NSCache and CIContext are internally thread-safe; the compiler can't prove it.
    nonisolated(unsafe) private static let cache = NSCache<NSString, NSImage>()
    nonisolated(unsafe) private static let context = CIContext()

    static func render(_ image: NSImage, style: IconStyle, key: String) -> NSImage {
        guard style != .original else { return image }
        let cacheKey = "\(key)|\(style.rawValue)" as NSString
        if let cached = cache.object(forKey: cacheKey) { return cached }

        let result: NSImage
        switch style {
        case .original: result = image
        case .tinted: result = monochrome(image, tint: NSColor(white: 0.75, alpha: 1)) ?? image
        case .clearColored: result = monochrome(image, tint: .controlAccentColor) ?? image
        case .dark: result = onBackground(image, background: NSColor(white: 0.12, alpha: 1))
        case .light: result = onBackground(image, background: NSColor(white: 0.95, alpha: 1))
        }
        cache.setObject(result, forKey: cacheKey)
        return result
    }

    private static func monochrome(_ image: NSImage, tint: NSColor) -> NSImage? {
        guard let tiff = image.tiffRepresentation, let input = CIImage(data: tiff) else { return nil }
        let filter = CIFilter.colorMonochrome()
        filter.inputImage = input
        filter.color = CIColor(color: tint) ?? CIColor(red: 0.7, green: 0.7, blue: 0.7)
        filter.intensity = 1
        guard let output = filter.outputImage,
              let cg = context.createCGImage(output, from: output.extent) else { return nil }
        return NSImage(cgImage: cg, size: image.size)
    }

    private static func onBackground(_ image: NSImage, background: NSColor) -> NSImage {
        let size = image.size
        let result = NSImage(size: size)
        result.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: size.width * 0.22, yRadius: size.height * 0.22)
        background.setFill()
        path.fill()
        let inset = rect.insetBy(dx: size.width * 0.12, dy: size.height * 0.12)
        image.draw(in: inset, from: .zero, operation: .sourceOver, fraction: 1)
        result.unlockFocus()
        return result
    }
}
#endif
