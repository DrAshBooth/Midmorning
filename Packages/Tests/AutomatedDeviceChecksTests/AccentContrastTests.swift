import Foundation
import XCTest

/// Ruling r21-02 (mm-t12b.29): the app uses the AccentColor asset, and the
/// text of a filled button contrasts with the accent at 3:1 or more in
/// light mode, in dark mode and with Increase Contrast (product-rules spec,
/// "Appearance" and "Accessibility everywhere"). A UI test cannot turn on
/// Increase Contrast (mm-t45.19), so these tests read the asset, the project
/// and the App sources. The contrast audits of
/// `AutomatedChecks+Accessibility.swift` measure the screens in light and
/// dark mode.
final class AccentContrastTests: XCTestCase {
    /// An sRGB colour as the asset catalogue holds it.
    struct RGB: Equatable, CustomStringConvertible {
        let red: Int, green: Int, blue: Int

        init(_ hex: Int) {
            red = (hex >> 16) & 0xFF
            green = (hex >> 8) & 0xFF
            blue = hex & 0xFF
        }

        init(red: Int, green: Int, blue: Int) {
            self.red = red
            self.green = green
            self.blue = blue
        }

        /// The relative luminance of WCAG 2.
        var luminance: Double {
            func channel(_ value: Int) -> Double {
                let c = Double(value) / 255
                return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
        }

        func contrast(with other: RGB) -> Double {
            let (a, b) = (luminance, other.luminance)
            return (max(a, b) + 0.05) / (min(a, b) + 0.05)
        }

        var description: String { String(format: "%02X%02X%02X", red, green, blue) }
    }

    static let white = RGB(0xFFFFFF)
    static let black = RGB(0x000000)
    /// The system background colour of a sheet in dark mode
    /// (`UIColor.systemBackground` at the elevated level; Apple's Human
    /// Interface Guidelines, "Color", 28 28 30).
    static let sheetDark = RGB(0x1C1C1E)
    /// The same with Increase Contrast on (36 36 38).
    static let sheetDarkIncreasedContrast = RGB(0x242426)

    /// The three values of the AccentColor asset: light, dark and Increase
    /// Contrast.
    private func accentValues() throws -> (light: RGB, dark: RGB, increasedContrast: RGB) {
        let url = AppFiles.appSources.appendingPathComponent("Assets.xcassets/AccentColor.colorset/Contents.json")
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let colours = try XCTUnwrap(json["colors"] as? [[String: Any]])
        var light: RGB?, dark: RGB?, increased: RGB?
        for entry in colours {
            let colour = try XCTUnwrap(entry["color"] as? [String: Any])
            XCTAssertEqual(colour["color-space"] as? String, "srgb")
            let components = try XCTUnwrap(colour["components"] as? [String: String])
            func value(_ key: String) throws -> Int {
                let text = try XCTUnwrap(components[key]).replacingOccurrences(of: "0x", with: "")
                return try XCTUnwrap(Int(text, radix: 16), "\(key) is a hexadecimal value")
            }
            let rgb = RGB(red: try value("red"), green: try value("green"), blue: try value("blue"))
            let appearances = (entry["appearances"] as? [[String: String]]) ?? []
            if appearances.isEmpty {
                light = rgb
            } else if appearances == [["appearance": "luminosity", "value": "dark"]] {
                dark = rgb
            } else if appearances == [["appearance": "contrast", "value": "high"]] {
                increased = rgb
            } else {
                XCTFail("the asset has a value for \(appearances): add it to this test")
            }
        }
        return (try XCTUnwrap(light, "a light value"), try XCTUnwrap(dark, "a dark value"),
                try XCTUnwrap(increased, "an Increase Contrast value"))
    }

    /// The Debug and the Release settings of the App target name the
    /// AccentColor asset as the global accent colour, so the built
    /// Info.plist holds NSAccentColorName and `Color.accentColor` is the
    /// asset, not the system blue.
    func testTheAppTargetUsesTheAccentColorAsset() throws {
        let project = try String(contentsOf: AppFiles.project, encoding: .utf8)
        let configurations = project.components(separatedBy: "isa = XCBuildConfiguration;").dropFirst()
            .filter { $0.contains("PRODUCT_BUNDLE_IDENTIFIER = uk.midmorning.app;") }
        let names = configurations.compactMap { block -> String? in
            guard let range = block.range(of: "name = ") else { return nil }
            return String(block[range.upperBound...].prefix { $0 != ";" })
        }
        XCTAssertEqual(names.sorted(), ["Debug", "Release"], "the App target has a Debug and a Release configuration")
        for (name, block) in zip(names, configurations) {
            XCTAssertTrue(block.contains("ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;"),
                          "the \(name) configuration of the App target names the AccentColor asset")
        }
    }

    /// product-rules "Appearance": each value of the asset contrasts with
    /// the row background at 3:1 or more (white in light mode, black in
    /// dark mode, either with Increase Contrast).
    func testEachAccentValueContrastsWithTheRowBackground() throws {
        let accent = try accentValues()
        XCTAssertGreaterThanOrEqual(accent.light.contrast(with: Self.white), 3, "light \(accent.light) on white")
        XCTAssertGreaterThanOrEqual(accent.dark.contrast(with: Self.black), 3, "dark \(accent.dark) on black")
        XCTAssertGreaterThanOrEqual(accent.dark.contrast(with: Self.sheetDark), 3, "dark \(accent.dark) on a sheet")
        for background in [Self.white, Self.black] {
            XCTAssertGreaterThanOrEqual(accent.increasedContrast.contrast(with: background), 3,
                                        "Increase Contrast \(accent.increasedContrast) on \(background)")
        }
    }

    /// Ruling r21-02: the text of a filled button is white in light mode
    /// and black or near-black in dark mode (the system background colour:
    /// `FilledButtonStyle`, and the keyboard's "Save" at the base level,
    /// black). Each text
    /// contrasts with each fill that
    /// can show with it at 3:1 or more. With Increase Contrast on in dark
    /// mode, the fill is the dark value or the Increase Contrast value, so
    /// the test checks both.
    func testTheTextOfAFilledButtonContrastsWithTheAccent() throws {
        let accent = try accentValues()
        let lightMode = [(accent.light, Self.white), (accent.increasedContrast, Self.white)]
        let darkMode = [Self.black, Self.sheetDark, Self.sheetDarkIncreasedContrast].flatMap { text in
            [(accent.dark, text), (accent.increasedContrast, text)]
        }
        for (fill, text) in lightMode + darkMode {
            XCTAssertGreaterThanOrEqual(fill.contrast(with: text), 3, "the text \(text) on the fill \(fill)")
        }
        // The fault that the ruling mends: white text on the dark value.
        XCTAssertLessThan(accent.dark.contrast(with: Self.white), 3, "white text on the dark value \(accent.dark) is under 3:1")
    }

    /// Every filled button uses `.buttonStyle(.filled)`. Only
    /// `FilledButtonStyle` in Appearance.swift uses `.borderedProminent`,
    /// and it gives the label the system background colour.
    func testEveryFilledButtonUsesTheSharedStyle() throws {
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(at: AppFiles.appSources, includingPropertiesForKeys: nil))
        var users: [String] = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let path = url.path.replacingOccurrences(of: AppFiles.appSources.path + "/", with: "")
            let code = try ScreenText.source(path)
            for style in [".borderedProminent", ".glassProminent", "BorderedProminentButtonStyle", "GlassProminentButtonStyle"]
            where code.contains(style) {
                users.append("\(path) \(style)")
            }
        }
        XCTAssertEqual(users, ["Appearance.swift .borderedProminent"], "only FilledButtonStyle uses a prominent style")
        let appearance = try ScreenText.source("Appearance.swift")
        XCTAssertTrue(appearance.contains("configuration.label.foregroundStyle(Color(uiColor: .systemBackground))"))
        XCTAssertTrue(appearance.contains("static var filled: FilledButtonStyle"))
    }

    /// "Save" on the keyboard's toolbar is a `.done` bar button item: a
    /// filled button on iOS 26 and later. Its text is the system background
    /// colour (product-rules "Appearance", ruling r21-02), from iOS 26 only
    /// (before iOS 26 the item has no fill). The provider resolves
    /// `UIColor.systemBackground` at the base level, because the colour as
    /// it is showed as a light blue on the keyboard's toolbar: white in
    /// light mode and black in dark mode. `assertTheKeyboardSaveContrasts`
    /// in the UI tests measures it in a screenshot.
    func testTheKeyboardSaveHasTheSystemBackgroundColourAsItsText() throws {
        let appearance = try ScreenText.source("Appearance.swift")
        XCTAssertTrue(appearance.contains("style: .done"))
        XCTAssertTrue(appearance.contains(
            "if #available(iOS 26.0, *) { let text = UIColor { traits in "
                + "UIColor.systemBackground.resolvedColor(with: traits.modifyingTraits { $0.userInterfaceLevel = .base }) } "
                + "for state: UIControl.State in [.normal, .highlighted] { save.setTitleTextAttributes([.foregroundColor: text], for: state) } }"
        ), "the keyboard's \"Save\" takes the system background colour as its text, on iOS 26 and later")
        for fixed in ["? .black : .white", "UIColor.black", "UIColor.white"] {
            XCTAssertFalse(appearance.contains(fixed), "Appearance.swift sets no fixed text colour (\(fixed)): product-rules \"Appearance\"")
        }
    }

    /// product-rules "Appearance": "System alerts, confirmation dialogs and
    /// swipe actions MUST also keep their system colours." SwiftUI gives an
    /// alert the tint of the place of its `.alert` modifier, and the root
    /// tint is the accent colour. So every alert of the App target is
    /// inside `alertInSystemColours` (Appearance.swift), which gives the
    /// alert the system blue and keeps the accent colour on the view. The
    /// swipe action keeps `.tint(.red)`.
    /// `AutomatedChecks.testAnAlertKeepsTheSystemBlue` in the UI tests
    /// measures "Cancel" of an alert in light mode and in dark mode.
    func testAlertsAndSwipeActionsKeepTheirSystemColours() throws {
        let appearance = try ScreenText.source("Appearance.swift")
        XCTAssertTrue(appearance.contains(
            "func alertInSystemColours<Alerted: View>(_ addAlert: (AccentTinted<Self>) -> Alerted) -> some View { "
                + "addAlert(AccentTinted(content: self)).tint(Color(uiColor: .systemBlue)) }"
        ), "the alert gets the system blue as its tint")
        XCTAssertTrue(appearance.contains("var body: some View { content.tint(Color.accentColor) }"), "the view under the alert keeps the accent colour")
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(at: AppFiles.appSources, includingPropertiesForKeys: nil))
        var alerts = 0
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let path = url.path.replacingOccurrences(of: AppFiles.appSources.path + "/", with: "")
            let code = Array(try ScreenText.source(path).filter { !$0.isWhitespace })
            func has(_ word: String, at index: Int) -> Bool {
                let characters = Array(word)
                return index + characters.count <= code.count && Array(code[index..<index + characters.count]) == characters
            }
            // Each "alert(" call (not "alertInSystemColours") is inside the
            // braces of an `alertInSystemColours { content in ... }`.
            var opened: [Int] = []  // the brace depth of each open alertInSystemColours block
            var depth = 0
            var index = 0
            while index < code.count {
                if has("alertInSystemColours{", at: index) {
                    opened.append(depth)
                    index += "alertInSystemColours".count
                    continue
                }
                if has("alert(", at: index), index == 0 || !(code[index - 1].isLetter || code[index - 1].isNumber) {
                    alerts += 1
                    XCTAssertFalse(opened.isEmpty, "\(path): an alert is not inside alertInSystemColours, so it shows the accent colour")
                }
                if code[index] == "{" { depth += 1 }
                if code[index] == "}" {
                    depth -= 1
                    if let last = opened.last, depth == last { opened.removeLast() }
                }
                index += 1
            }
        }
        XCTAssertEqual(alerts, 9, "the App target has nine alerts (ruling r16-03); a new one goes through alertInSystemColours")
        XCTAssertTrue(try ScreenText.source("DaySectionView.swift").contains(".swipeActions(edge: .trailing) { Button { askToDelete(entry) } label: { Text(\"entry.delete.action\") } .tint(.red) }"),
                      "the swipe action \"Delete\" keeps the system red")
    }
}
