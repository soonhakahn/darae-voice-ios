#!/usr/bin/env swift
import Foundation
import AppKit

// Create a 1024x1024 PNG app icon with a clean brand look:
// - Deep navy → blue gradient background
// - Subtle rounded rectangle highlight
// - White waveform + orange leaf SF Symbols

let size = 1024
let outURL = URL(fileURLWithPath: "Assets/AppIconBase-1024.png")

func cgColor(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

let colorSpace = CGColorSpaceCreateDeviceRGB()
let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// Flip coordinate system (Quartz origin bottom-left → top-left)
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

// Background gradient
let grad = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        cgColor(0.06, 0.09, 0.16),
        cgColor(0.12, 0.23, 0.55)
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawLinearGradient(
    grad,
    start: CGPoint(x: 0, y: 0),
    end: CGPoint(x: CGFloat(size), y: CGFloat(size)),
    options: []
)

// Subtle highlight card
let cardRect = CGRect(x: 110, y: 120, width: 804, height: 784)
let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 160, cornerHeight: 160, transform: nil)
ctx.setFillColor(cgColor(0, 0, 0, 0.14))
ctx.addPath(cardPath)
ctx.fillPath()

// Symbols
func drawSymbol(name: String, rect: CGRect, color: NSColor, weight: NSFont.Weight = .semibold) {
    let config = NSImage.SymbolConfiguration(pointSize: rect.height, weight: weight)
    guard let img = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(config) else {
        return
    }
    let tinted = img.copy() as! NSImage
    tinted.isTemplate = true

    ctx.saveGState()
    // Render via NSGraphicsContext
    let nsCtx = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = nsCtx
    color.set()
    tinted.draw(in: rect, from: .zero, operation: .sourceAtop, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()
    ctx.restoreGState()
}

// Waveform (white)
drawSymbol(name: "waveform.path.ecg", rect: CGRect(x: 270, y: 300, width: 480, height: 480), color: .white, weight: .semibold)

// Leaf (orange) overlay
let leafRect = CGRect(x: 640, y: 220, width: 260, height: 260)
drawSymbol(name: "leaf.fill", rect: leafRect, color: NSColor(calibratedRed: 0.98, green: 0.58, blue: 0.13, alpha: 1.0), weight: .bold)

// Export PNG
let cgImg = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: cgImg)
rep.size = NSSize(width: size, height: size)
let png = rep.representation(using: .png, properties: [:])!
try FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outURL)

print("Wrote: \(outURL.path)")
