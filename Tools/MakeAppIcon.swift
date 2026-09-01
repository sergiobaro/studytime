import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Renders the studytime app icon: a timer ring with clock hands.
// Everything is expressed as a fraction of the content square, so a size is
// drawn directly rather than downscaled — 16x16 stays crisp.

enum Style {
    case colorFullBleed   // iOS 1024: system masks the corners
    case colorMac         // macOS: own squircle, inset with a soft shadow
    case artworkOnly      // iOS dark: artwork on transparent
    case tinted           // iOS tinted: grayscale artwork on transparent
}

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

/// Superellipse ("squircle") close to the macOS icon shape.
func squircle(in rect: CGRect, radiusFraction: Double) -> CGPath {
    let path = CGMutablePath()
    let n = 5.0
    let a = rect.width / 2, b = rect.height / 2
    let cx = rect.midX, cy = rect.midY
    let steps = 720
    for i in 0...steps {
        let t = Double(i) / Double(steps) * 2 * .pi
        let ct = cos(t), st = sin(t)
        let x = cx + a * copysign(pow(abs(ct), 2 / n), ct)
        let y = cy + b * copysign(pow(abs(st), 2 / n), st)
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

func drawIcon(size S: Double, style: Style) -> CGImage {
    let px = Int(S)
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setAllowsAntialiasing(true)
    ctx.interpolationQuality = .high

    // Content square: full canvas on iOS, inset on macOS.
    let inset = style == .colorMac ? S * 0.0977 : 0
    let content = CGRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
    let C = content.width

    // Background
    if style == .colorFullBleed || style == .colorMac {
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  colors: [rgb(0.17, 0.21, 0.34), rgb(0.07, 0.09, 0.13)] as CFArray,
                                  locations: [0, 1])!
        ctx.saveGState()
        if style == .colorMac {
            ctx.setShadow(offset: CGSize(width: 0, height: -C * 0.012),
                          blur: C * 0.035, color: rgb(0, 0, 0, 0.35))
            ctx.beginTransparencyLayer(auxiliaryInfo: nil)
            ctx.addPath(squircle(in: content, radiusFraction: 0.28))
            ctx.clip()
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: content.minX, y: content.maxY),
                                   end: CGPoint(x: content.maxX, y: content.minY),
                                   options: [])
            ctx.endTransparencyLayer()
        } else {
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: S),
                                   end: CGPoint(x: S, y: 0),
                                   options: [])
        }
        ctx.restoreGState()
    }

    let cx = content.midX, cy = content.midY
    let radius = C * 0.295
    let ringWidth = C * 0.078

    // Ring track
    ctx.setLineWidth(ringWidth)
    ctx.setLineCap(.round)
    ctx.setStrokeColor(style == .tinted ? rgb(1, 1, 1, 0.22) : rgb(1, 1, 1, 0.13))
    ctx.addArc(center: CGPoint(x: cx, y: cy), radius: radius,
               startAngle: 0, endAngle: 2 * .pi, clockwise: false)
    ctx.strokePath()

    // Progress arc: three quarters, clockwise from twelve o'clock.
    ctx.saveGState()
    ctx.addArc(center: CGPoint(x: cx, y: cy), radius: radius,
               startAngle: .pi / 2, endAngle: -.pi, clockwise: true)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    if style == .tinted {
        ctx.setFillColor(rgb(1, 1, 1))
        ctx.fill(content)
    } else {
        let warm = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                              colors: [rgb(1.00, 0.78, 0.32), rgb(1.00, 0.45, 0.35)] as CFArray,
                              locations: [0, 1])!
        ctx.drawLinearGradient(warm,
                               start: CGPoint(x: cx - radius, y: cy + radius),
                               end: CGPoint(x: cx + radius, y: cy - radius),
                               options: [])
    }
    ctx.restoreGState()

    // Hands
    ctx.setStrokeColor(style == .tinted ? rgb(1, 1, 1, 0.85) : rgb(0.96, 0.95, 0.92))
    ctx.setLineWidth(C * 0.048)
    ctx.move(to: CGPoint(x: cx, y: cy))
    ctx.addLine(to: CGPoint(x: cx, y: cy + C * 0.175))
    ctx.strokePath()
    ctx.move(to: CGPoint(x: cx, y: cy))
    ctx.addLine(to: CGPoint(x: cx + C * 0.113, y: cy - C * 0.065))
    ctx.strokePath()

    return ctx.makeImage()!
}

func write(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let out = CommandLine.arguments[1]
write(drawIcon(size: 1024, style: .colorFullBleed), to: "\(out)/icon-1024.png")
write(drawIcon(size: 1024, style: .artworkOnly), to: "\(out)/icon-1024-dark.png")
write(drawIcon(size: 1024, style: .tinted), to: "\(out)/icon-1024-tinted.png")
for s in [16, 32, 64, 128, 256, 512, 1024] {
    write(drawIcon(size: Double(s), style: .colorMac), to: "\(out)/icon-mac-\(s).png")
}
print("done")
