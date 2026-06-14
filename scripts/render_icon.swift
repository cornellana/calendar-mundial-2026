//
// render_icon.swift
// CalendarMundial
//
// Genera el icono de la app (1024×1024 PNG sin canal alfa) usando CoreGraphics
// puro y CoreText. NO usar AppKit: NSGraphicsContext falla en línea de comandos
// y produce un PNG negro. App Store rechaza iconos de iOS con transparencia,
// por eso usamos `CGImageAlphaInfo.noneSkipLast`.
//
// Uso:
//   swift scripts/render_icon.swift <ruta-salida-opcional>
//
// Sin argumentos escribe en
// CalendarMundial/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Parámetros del lienzo

/// Tamaño de salida en píxeles. 1024 es el único requerido para iOS desde Xcode 14.
let canvasSize: CGFloat = 1024
let canvas = CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize)

guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
    fputs("Error: no se pudo crear el color space sRGB\n", stderr)
    exit(1)
}

// noneSkipLast = sin canal alfa. Imprescindible para los iconos de iOS.
let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue

guard let ctx = CGContext(
    data: nil,
    width: Int(canvasSize),
    height: Int(canvasSize),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: bitmapInfo
) else {
    fputs("Error: no se pudo crear el CGContext\n", stderr)
    exit(1)
}

// MARK: - Fondo: degradado diagonal azul marino

let backgroundColors = [
    CGColor(red: 0.039, green: 0.059, blue: 0.118, alpha: 1.0), // #0A0F1E
    CGColor(red: 0.051, green: 0.122, blue: 0.235, alpha: 1.0), // #0D1F3C
    CGColor(red: 0.039, green: 0.059, blue: 0.118, alpha: 1.0)  // #0A0F1E
] as CFArray

guard let backgroundGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: backgroundColors,
    locations: [0.0, 0.5, 1.0]
) else {
    fputs("Error: no se pudo crear el gradiente de fondo\n", stderr)
    exit(1)
}

ctx.drawLinearGradient(
    backgroundGradient,
    start: CGPoint(x: 0, y: canvasSize),
    end: CGPoint(x: canvasSize, y: 0),
    options: []
)

// MARK: - Aro exterior dorado translúcido

ctx.setStrokeColor(CGColor(red: 0.78, green: 0.66, blue: 0.29, alpha: 0.18))
ctx.setLineWidth(6)
ctx.strokeEllipse(in: canvas.insetBy(dx: 50, dy: 50))

// MARK: - Disco dorado central

let discRect = CGRect(x: 152, y: 152, width: 720, height: 720)

let discColors = [
    CGColor(red: 0.94, green: 0.82, blue: 0.44, alpha: 1.0), // #F0D070
    CGColor(red: 0.78, green: 0.66, blue: 0.29, alpha: 1.0)  // #C8A84B
] as CFArray

guard let discGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: discColors,
    locations: [0.0, 1.0]
) else {
    fputs("Error: no se pudo crear el gradiente del disco\n", stderr)
    exit(1)
}

ctx.saveGState()
ctx.addEllipse(in: discRect)
ctx.clip()
ctx.drawLinearGradient(
    discGradient,
    start: CGPoint(x: discRect.minX, y: discRect.maxY),
    end: CGPoint(x: discRect.maxX, y: discRect.minY),
    options: []
)
ctx.restoreGState()

// Sombra interior del disco para profundidad
ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.22))
ctx.setLineWidth(8)
ctx.strokeEllipse(in: discRect.insetBy(dx: 8, dy: 8))

// MARK: - Balón ⚽ centrado (CoreText, no AppKit)

let emoji = "⚽" as CFString
// AppleColorEmoji es la fuente del sistema para emojis a todo color.
let emojiFont = CTFontCreateWithName("AppleColorEmoji" as CFString, 540, nil)
let emojiAttributes: [CFString: Any] = [
    kCTFontAttributeName: emojiFont
]

guard let attributedEmoji = CFAttributedStringCreate(
    nil,
    emoji,
    emojiAttributes as CFDictionary
) else {
    fputs("Error: no se pudo crear el AttributedString del emoji\n", stderr)
    exit(1)
}

let emojiLine = CTLineCreateWithAttributedString(attributedEmoji)
let emojiBounds = CTLineGetImageBounds(emojiLine, ctx)

// Centrar la caja real del glifo (no la métrica) en el canvas.
let originX = (canvasSize - emojiBounds.width) / 2 - emojiBounds.minX
let originY = (canvasSize - emojiBounds.height) / 2 - emojiBounds.minY

ctx.textPosition = CGPoint(x: originX, y: originY)
CTLineDraw(emojiLine, ctx)

// MARK: - Exportar PNG

guard let cgImage = ctx.makeImage() else {
    fputs("Error: no se pudo crear el CGImage\n", stderr)
    exit(1)
}

let outputPath: String
if CommandLine.arguments.count > 1 {
    outputPath = CommandLine.arguments[1]
} else {
    let cwd = FileManager.default.currentDirectoryPath
    outputPath = "\(cwd)/CalendarMundial/CalendarMundial/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
}

let outputURL = URL(fileURLWithPath: outputPath) as CFURL

guard let destination = CGImageDestinationCreateWithURL(
    outputURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fputs("Error: no se pudo crear CGImageDestination\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, cgImage, nil)

guard CGImageDestinationFinalize(destination) else {
    fputs("Error: no se pudo finalizar el PNG\n", stderr)
    exit(1)
}

print("Icono generado: \(outputPath)")
