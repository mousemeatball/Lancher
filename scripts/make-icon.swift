#!/usr/bin/env swift
// Generates Lancher's app icon (.icns) from scratch — no external assets.
//
// Draws a gradient rounded-square with a 3×3 grid of rounded tiles (echoing the menu-bar
// "square.grid.3x3" symbol), renders every size macOS wants, and runs `iconutil` to pack a
// .icns. Pure CoreGraphics/ImageIO so it works headless (no window server needed).
//
// Usage: swift make-icon.swift <out.icns> [<out-1024.png>]

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

func makeContext(_ px: Int) -> CGContext {
    CGContext(
        data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
        space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
}

func drawIcon(_ ctx: CGContext, _ size: CGFloat) {
    let inset = size * 0.075
    let rect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let radius = rect.width * 0.2237
    let rounded = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    ctx.saveGState()
    ctx.addPath(rounded)
    ctx.clip()
    let colors = [
        CGColor(red: 0.36, green: 0.42, blue: 1.00, alpha: 1),  // indigo
        CGColor(red: 0.55, green: 0.28, blue: 0.96, alpha: 1),  // violet
    ] as CFArray
    let gradient = CGGradient(colorsSpace: sRGB, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )
    ctx.restoreGState()

    // 3×3 grid of rounded white tiles.
    let count = 3
    let area = rect.insetBy(dx: rect.width * 0.23, dy: rect.height * 0.23)
    let gap = area.width * 0.16
    let cell = (area.width - gap * CGFloat(count - 1)) / CGFloat(count)
    let cellRadius = cell * 0.30
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    for row in 0..<count {
        for col in 0..<count {
            let origin = CGPoint(
                x: area.minX + CGFloat(col) * (cell + gap),
                y: area.minY + CGFloat(row) * (cell + gap)
            )
            let tile = CGRect(origin: origin, size: CGSize(width: cell, height: cell))
            ctx.addPath(CGPath(roundedRect: tile, cornerWidth: cellRadius, cornerHeight: cellRadius, transform: nil))
            ctx.fillPath()
        }
    }
}

func writePNG(_ px: Int, to url: URL) throws {
    let ctx = makeContext(px)
    drawIcon(ctx, CGFloat(px))
    guard let image = ctx.makeImage() else { throw Err("makeImage failed at \(px)px") }
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        throw Err("CGImageDestination failed for \(url.path)")
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else { throw Err("PNG finalize failed for \(url.path)") }
}

struct Err: Error, CustomStringConvertible { let m: String; init(_ m: String) { self.m = m }; var description: String { m } }

// MARK: - Main

do {
    let args = CommandLine.arguments
    guard args.count >= 2 else { throw Err("usage: make-icon.swift <out.icns> [out-1024.png]") }
    let icnsURL = URL(fileURLWithPath: args[1])

    let iconset = FileManager.default.temporaryDirectory.appending(path: "Lancher-\(UUID().uuidString).iconset")
    try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: iconset) }

    let specs: [(String, Int)] = [
        ("icon_16x16", 16), ("icon_16x16@2x", 32),
        ("icon_32x32", 32), ("icon_32x32@2x", 64),
        ("icon_128x128", 128), ("icon_128x128@2x", 256),
        ("icon_256x256", 256), ("icon_256x256@2x", 512),
        ("icon_512x512", 512), ("icon_512x512@2x", 1024),
    ]
    for (name, px) in specs {
        try writePNG(px, to: iconset.appending(path: "\(name).png"))
    }

    let iconutil = Process()
    iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    iconutil.arguments = ["-c", "icns", iconset.path, "-o", icnsURL.path]
    try iconutil.run()
    iconutil.waitUntilExit()
    guard iconutil.terminationStatus == 0 else { throw Err("iconutil exited \(iconutil.terminationStatus)") }

    if args.count >= 3 { try writePNG(1024, to: URL(fileURLWithPath: args[2])) }
    print("Wrote \(icnsURL.path)")
} catch {
    FileHandle.standardError.write("make-icon: \(error)\n".data(using: .utf8)!)
    exit(1)
}
