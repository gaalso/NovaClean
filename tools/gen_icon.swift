//
//  gen_icon.swift — gera o ícone AppIcon (todas as resoluções do .iconset)
//  Identidade "Nova": gradiente violeta→magenta + anel orbital + sparkle de 4 pontas.
//
//  Uso: gen_icon.swift <largura_px> <arquivo_saida.png>
//

import AppKit

let args = CommandLine.arguments
if args.count < 3 {
    FileHandle.standardError.write("uso: gen_icon.swift <size_px> <out.png>\n".data(using: .utf8)!)
    exit(2)
}
let size = Int(args[1])!
let outPath = args[2]

let S: CGFloat = CGFloat(size)
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: size,
    pixelsHigh: size,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// --- margem para tiles menores (macOS espera ~10% de recuo) ---
let margin = (size <= 64) ? S * 0.06 : S * 0.10
let bodyRect = CGRect(x: margin, y: margin, width: S - margin * 2, height: S - margin * 2)

// --- 1) fundo: rounded rect + gradiente de marca ---
let bg = NSBezierPath(roundedRect: bodyRect, xRadius: bodyRect.width * 0.225, yRadius: bodyRect.width * 0.225)
bg.addClip()
NSColor(calibratedRed: 0.06, green: 0.06, blue: 0.09, alpha: 1).setFill()
bg.fill()

let grad = NSGradient(colors: [
    NSColor(calibratedRed: 0.478, green: 0.173, blue: 1.000, alpha: 1), // #7A2CFF
    NSColor(calibratedRed: 0.647, green: 0.173, blue: 1.000, alpha: 1), // #A52CFF
    NSColor(calibratedRed: 1.000, green: 0.243, blue: 0.557, alpha: 1)  // #FF3E8E
])!
grad.draw(in: bg, angle: -45)

// --- 2) glow radial no canto superior esquerdo (profundidade "nova") ---
let glowRect = CGRect(x: bodyRect.minX - bodyRect.width * 0.15,
                      y: bodyRect.maxY - bodyRect.height * 0.85,
                      width: bodyRect.width * 0.9,
                      height: bodyRect.height * 0.9)
let glow = NSGradient(colors: [
    NSColor(white: 1, alpha: 0.30),
    NSColor(white: 1, alpha: 0.0)
])!
let glowPath = NSBezierPath(ovalIn: glowRect)
glow.draw(in: glowPath, relativeCenterPosition: NSPoint(x: 0.5, y: 0.5))

// --- 3) anel orbital ---
let ringCenter = NSPoint(x: bodyRect.midX, y: bodyRect.midY - bodyRect.height * 0.02)
let ringRadius = bodyRect.width * 0.335
let ring = NSBezierPath()
ring.appendArc(withCenter: ringCenter, radius: ringRadius, startAngle: 0, endAngle: 359.9, clockwise: false)
ring.lineWidth = bodyRect.width * 0.045
NSColor(white: 1, alpha: 0.38).setStroke()
ring.stroke()

// --- 4) sparkle de 4 pontas ---
func sparklePath(center: NSPoint, outer: CGFloat, inner: CGFloat) -> NSBezierPath {
    let p = NSBezierPath()
    for i in 0..<8 {
        let angle = CGFloat(i) * .pi / 4 + .pi / 2 // começa no topo
        let r = (i % 2 == 0) ? outer : inner
        let pt = NSPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
        if i == 0 { p.move(to: pt) } else { p.line(to: pt) }
    }
    p.close()
    return p
}

let main = sparklePath(center: NSPoint(x: ringCenter.x + bodyRect.width * 0.015,
                                       y: ringCenter.y + bodyRect.height * 0.015),
                       outer: bodyRect.width * 0.27,
                       inner: bodyRect.width * 0.105)
NSColor.white.setFill()
main.fill()

let mini = sparklePath(center: NSPoint(x: bodyRect.minX + bodyRect.width * 0.24,
                                       y: bodyRect.minY + bodyRect.height * 0.22),
                       outer: bodyRect.width * 0.075,
                       inner: bodyRect.width * 0.030)
mini.fill()

NSGraphicsContext.restoreGraphicsState()

// --- exportar PNG ---
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath) (\(size)px)")
