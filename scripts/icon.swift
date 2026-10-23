// Draws Tape's app icon: a cassette on a warm squircle. scripts/icon.sh runs it and builds
// support/icon.png and support/AppIcon.icns from the result. Usage: swift scripts/icon.swift OUT.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments[1]

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255,
             blue: CGFloat(hex & 0xff) / 255, alpha: a)
}

// Top-left coordinates, like a design tool.
func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> NSRect {
    NSRect(x: x, y: size - y - h, width: w, height: h)
}

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext

// Background squircle on Apple's icon grid (824 px body, 100 px margin).
let body = NSBezierPath(roundedRect: rect(100, 100, 824, 824), xRadius: 186, yRadius: 186)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: color(0x000000, 0.28).cgColor)
color(0xF3582C).setFill()
body.fill()
ctx.restoreGState()
NSGradient(starting: color(0xFFA24A), ending: color(0xEE4B2B))!.draw(in: body, angle: -90)

// Cassette shell.
let shell = NSBezierPath(roundedRect: rect(188, 290, 648, 444), xRadius: 44, yRadius: 44)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 20, color: color(0x5A1A08, 0.35).cgColor)
color(0x24232A).setFill()
shell.fill()
ctx.restoreGState()

// Label across the top, with a red record dot.
color(0xFBF3E6).setFill()
NSBezierPath(roundedRect: rect(232, 330, 560, 120), xRadius: 18, yRadius: 18).fill()
color(0xEE4B2B).setFill()
NSBezierPath(ovalIn: rect(268, 362, 56, 56)).fill()
color(0x24232A, 0.22).setFill()
NSBezierPath(roundedRect: rect(352, 368, 380, 14), xRadius: 7, yRadius: 7).fill()
NSBezierPath(roundedRect: rect(352, 398, 260, 14), xRadius: 7, yRadius: 7).fill()

// Window with the two reels.
color(0x3A3842).setFill()
NSBezierPath(roundedRect: rect(262, 488, 500, 150), xRadius: 75, yRadius: 75).fill()
for cx in [CGFloat(362), 662] {
    let cy: CGFloat = 563
    // Tape wound on the reel.
    color(0x7A4A2E).setFill()
    NSBezierPath(ovalIn: rect(cx - 62, cy - 62, 124, 124)).fill()
    // Reel hub with six teeth.
    color(0xFBF3E6).setFill()
    NSBezierPath(ovalIn: rect(cx - 38, cy - 38, 76, 76)).fill()
    color(0x24232A).setFill()
    NSBezierPath(ovalIn: rect(cx - 18, cy - 18, 36, 36)).fill()
    for k in 0..<6 {
        let a = CGFloat(k) * .pi / 3
        let p = NSPoint(x: cx + cos(a) * 28, y: cy + sin(a) * 28)
        NSBezierPath(ovalIn: rect(p.x - 6, p.y - 6, 12, 12)).fill()
    }
}

// Head opening at the bottom.
let head = NSBezierPath()
head.move(to: NSPoint(x: 352, y: size - 734))
head.line(to: NSPoint(x: 384, y: size - 674))
head.line(to: NSPoint(x: 640, y: size - 674))
head.line(to: NSPoint(x: 672, y: size - 734))
head.close()
color(0x3A3842).setFill()
head.fill()
for x in [CGFloat(420), 588] {
    color(0x24232A).setFill()
    NSBezierPath(ovalIn: rect(x - 14, 690, 28, 28)).fill()
}

image.unlockFocus()
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
