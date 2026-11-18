import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum FixtureError: Error { case arguments, provider, image, destination, encoding, date }
guard CommandLine.arguments.count == 2 else { throw FixtureError.arguments }
let output = URL(fileURLWithPath: CommandLine.arguments[1])
let pixels = Data(repeating: 128, count: 32 * 32 * 4)
guard let provider = CGDataProvider(data: pixels as CFData) else { throw FixtureError.provider }
guard let image = CGImage(width: 32, height: 32, bitsPerComponent: 8, bitsPerPixel: 32,
    bytesPerRow: 128, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
    provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
else { throw FixtureError.image }
guard let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)
else { throw FixtureError.destination }
CGImageDestinationAddImage(destination, image, [
    kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2021:07:15 12:30:00"]
] as CFDictionary)
guard CGImageDestinationFinalize(destination) else { throw FixtureError.encoding }
let formatter = DateFormatter()
formatter.locale = Locale(identifier: "en_US_POSIX")
formatter.timeZone = .current
formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
guard let metadataDate = formatter.date(from: "2021:07:15 12:30:00") else { throw FixtureError.date }
formatter.dateFormat = "yyyy-MM-dd HH-mm"
guard let forcedDate = formatter.date(from: "2020-01-02 03-04") else { throw FixtureError.date }
let result = try JSONSerialization.data(withJSONObject: [
    "metadataTimestamp": metadataDate.timeIntervalSince1970,
    "forcedTimestamp": forcedDate.timeIntervalSince1970
], options: [.sortedKeys])
print(String(decoding: result, as: UTF8.self))
