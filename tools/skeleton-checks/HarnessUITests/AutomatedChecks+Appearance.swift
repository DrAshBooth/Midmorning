import XCTest
import UIKit

/// product-rules "Appearance": "System alerts, confirmation dialogs and
/// swipe actions MUST also keep their system colours." Ruling r21-02
/// (mm-t12b.29) gives the app the AccentColor asset as its global accent
/// colour, and UIKit then tints each alert with it: "Cancel" showed 1F4E79
/// in light mode and 7CB4E6 in dark mode (9 October 2026).
/// `View.alertInSystemColours` (App/Midmorning/Appearance.swift) gives each
/// alert the system blue. These tests measure the colour of the text in a
/// screenshot.
extension AutomatedChecks {
    /// An sRGB colour, each part from 0 to 1.
    struct ScreenColour: CustomStringConvertible {
        let red: Double, green: Double, blue: Double

        init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        init(hex: Int) {
            self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
        }

        init(_ colour: UIColor, dark: Bool) {
            var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            colour.resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light)).getRed(&r, green: &g, blue: &b, alpha: &a)
            self.init(red: Double(r), green: Double(g), blue: Double(b))
        }

        func distance(to other: ScreenColour) -> Double {
            ((red - other.red) * (red - other.red) + (green - other.green) * (green - other.green) + (blue - other.blue) * (blue - other.blue)).squareRoot()
        }

        var description: String {
            String(format: "%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
        }
    }

    /// The colour of the text inside `frame` of a screenshot. The test
    /// measures inside the frame, clear of the rounded ends of a button, as
    /// `measuredContrast` does. The background is the median pixel. The
    /// text is the mean of the 2 per cent of pixels that differ most from
    /// the background: the middle of each glyph, not its soft edge.
    func textColour(in frame: CGRect, of image: CGImage, scale: CGFloat) -> (text: ScreenColour, background: ScreenColour)? {
        let inner = frame.insetBy(dx: min(16, frame.width / 4), dy: frame.height * 0.2)
        let rect = CGRect(x: inner.minX * scale, y: inner.minY * scale, width: inner.width * scale, height: inner.height * scale)
            .integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard !rect.isEmpty, let cropped = image.cropping(to: rect), let space = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let width = cropped.width, height = cropped.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn, width * height > 0 else { return nil }
        let colours = stride(from: 0, to: pixels.count, by: 4).map {
            ScreenColour(red: Double(pixels[$0]) / 255, green: Double(pixels[$0 + 1]) / 255, blue: Double(pixels[$0 + 2]) / 255)
        }
        let byLightness = colours.sorted { $0.red + $0.green + $0.blue < $1.red + $1.green + $1.blue }
        let background = byLightness[byLightness.count / 2]
        let farthest = colours.sorted { $0.distance(to: background) > $1.distance(to: background) }.prefix(max(1, colours.count / 50))
        let count = Double(farthest.count)
        let text = ScreenColour(red: farthest.map(\.red).reduce(0, +) / count, green: farthest.map(\.green).reduce(0, +) / count,
                                blue: farthest.map(\.blue).reduce(0, +) / count)
        return (text, background)
    }

    /// The two colours that the tests tell apart: the system blue and the
    /// value of the AccentColor asset in the mode (light 1F4E79, dark
    /// 7CB4E6).
    enum ExpectedTint: String {
        case systemBlue = "the system blue"
        case accent = "the accent colour"
    }

    /// The text of `element` shows `expected`, not the other colour of
    /// `ExpectedTint`.
    func assertTextColour(_ element: XCUIElement, _ description: String, is expected: ExpectedTint, dark: Bool,
                          file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), "\(description) shows", file: file, line: line)
        sleep(1)
        guard let image = XCUIScreen.main.screenshot().image.cgImage else {
            XCTFail("no screenshot", file: file, line: line)
            return
        }
        let scale = CGFloat(image.width) / max(app.windows.firstMatch.frame.width, 1)
        guard let measured = textColour(in: element.frame, of: image, scale: scale) else {
            XCTFail("\(description): no pixels in the frame \(element.frame)", file: file, line: line)
            return
        }
        let systemBlue = ScreenColour(.systemBlue, dark: dark)
        let accent = ScreenColour(hex: dark ? 0x7CB4E6 : 0x1F4E79)
        let (wanted, other) = expected == .systemBlue ? (systemBlue, accent) : (accent, systemBlue)
        let mode = dark ? "dark mode" : "light mode"
        let summary = "\(description) in \(mode): the text measured \(measured.text) on \(measured.background); "
            + "the system blue is \(systemBlue), the accent colour \(accent)"
        auditLog("  (\(summary))")
        XCTAssertLessThan(measured.text.distance(to: wanted), measured.text.distance(to: other),
                          "\(summary): the text is not \(expected.rawValue)", file: file, line: line)
        XCTAssertLessThan(measured.text.distance(to: wanted), 0.2, "\(summary): the text is not \(expected.rawValue)", file: file, line: line)
    }

    /// product-rules "Appearance" (ruling r21-02, mm-t12b.29): an alert
    /// keeps its system colours with the AccentColor asset on, and a control
    /// uses the accent colour. On Settings (`week1`) "Get support" shows the
    /// accent colour. "Delete everything" shows the alert "Delete
    /// everything?", and its "Cancel" shows the system blue. The test does
    /// this in light mode and in dark mode. Each alert of the app gets its
    /// colour from the same place (`alertInSystemColours`;
    /// `AccentContrastTests` proves that each alert uses it), so one alert
    /// proves the rule for each of them.
    func testAnAlertKeepsTheSystemBlue() throws {
        addTeardownBlock { XCUIDevice.shared.appearance = .light }
        for dark in [false, true] {
            XCUIDevice.shared.appearance = dark ? .dark : .light
            try launchOnToday("week1")
            if dark { assertDarkMode() }
            tapToolbar("Settings")
            assertScreen("Settings")
            assertTextColour(app.navigationBars["Settings"].buttons["Get support"].firstMatch, "\"Get support\" on Settings", is: .accent, dark: dark)
            let delete = app.buttons["Delete everything"].firstMatch
            XCTAssertTrue(scrollTo(delete), "the Privacy group shows \"Delete everything\"")
            delete.tap()
            let alert = app.alerts.firstMatch
            XCTAssertTrue(alert.waitForExistence(timeout: 5), "\"Delete everything\" shows an alert")
            assertTextColour(alert.buttons["Cancel"], "\"Cancel\" of \"Delete everything?\"", is: .systemBlue, dark: dark)
            alert.buttons["Cancel"].tap()
            XCTAssertTrue(alert.waitForNonExistence(timeout: 5), "\"Cancel\" closes the alert")
        }
    }
}
