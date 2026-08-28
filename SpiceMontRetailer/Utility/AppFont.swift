//
//  AppFont.swift
//  SpiceMontRetailer
//

import SwiftUI
import UIKit
import CoreText

public enum AppFont {
    public static let regular = "DMSans-Regular"
    public static let medium = "DMSans-Medium"
    public static let bold = "DMSans-Bold"
    public static let italic = "DMSans-Italic"
    public static let boldItalic = "DMSans-BoldItalic"

    public static func postScriptName(for weight: Font.Weight, isItalic: Bool = false) -> String {
        if isItalic {
            if weight == .bold || weight == .heavy || weight == .black {
                return boldItalic
            }
            return italic
        }

        switch weight {
        case .bold, .heavy, .black:
            return bold
        case .medium, .semibold:
            return medium
        default:
            return regular
        }
    }

    public static func postScriptName(for uiWeight: UIFont.Weight, isItalic: Bool = false) -> String {
        if isItalic {
            if uiWeight >= .bold {
                return boldItalic
            }
            return italic
        }

        if uiWeight >= .bold {
            return bold
        } else if uiWeight >= .medium {
            return medium
        } else {
            return regular
        }
    }

    private static var didRegisterFonts = false

    /// Automatically register font files from bundle if needed
    public static func registerFontsIfNeeded() {
        guard !didRegisterFonts else { return }
        didRegisterFonts = true

        let fontNames = [
            "DMSans-Regular",
            "DMSans-Medium",
            "DMSans-Bold",
            "DMSans-Italic",
            "DMSans-BoldItalic",
            "DMSans-Variable"
        ]

        for fontName in fontNames {
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: "ttf") {
                var error: Unmanaged<CFError>?
                CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)
            }
        }
    }
}

// MARK: - SwiftUI Font Extensions

public extension Font {
    /// Standard DM Sans font matching size and weight
    static func appFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, isItalic: Bool = false) -> Font {
        AppFont.registerFontsIfNeeded()
        let name = AppFont.postScriptName(for: weight, isItalic: isItalic)
        return Font.custom(name, size: size)
    }

    /// Convenience shortcut for DM Sans font
    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default, isItalic: Bool = false) -> Font {
        appFont(size: size, weight: weight, design: design, isItalic: isItalic)
    }

    // Typography presets
    static var dmTitle1: Font { .dmSans(28, weight: .bold) }
    static var dmTitle2: Font { .dmSans(22, weight: .bold) }
    static var dmTitle3: Font { .dmSans(19, weight: .bold) }
    static var dmHeadline: Font { .dmSans(16, weight: .bold) }
    static var dmSubheadline: Font { .dmSans(14, weight: .medium) }
    static var dmBody: Font { .dmSans(14, weight: .regular) }
    static var dmBodyBold: Font { .dmSans(14, weight: .bold) }
    static var dmCallout: Font { .dmSans(13, weight: .medium) }
    static var dmCaption1: Font { .dmSans(12, weight: .regular) }
    static var dmCaption2: Font { .dmSans(11, weight: .medium) }
}

// MARK: - UIKit UIFont Extensions

public extension UIFont {
    /// UIKit DM Sans font with graceful system fallback
    static func appFont(size: CGFloat, weight: UIFont.Weight = .regular, isItalic: Bool = false) -> UIFont {
        AppFont.registerFontsIfNeeded()
        let name = AppFont.postScriptName(for: weight, isItalic: isItalic)
        return UIFont(name: name, size: size) ?? (isItalic ? UIFont.italicSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size, weight: weight))
    }

    /// Convenience shortcut for UIKit DM Sans
    static func dmSans(_ size: CGFloat, weight: UIFont.Weight = .regular, isItalic: Bool = false) -> UIFont {
        appFont(size: size, weight: weight, isItalic: isItalic)
    }
}
