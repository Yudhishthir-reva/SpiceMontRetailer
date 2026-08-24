//
//  Color+Extension.swift
//  SpiceMonk
//

import SwiftUI
import UIKit

extension Color {
    init(hex: String, opacity: Double = 1) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)

        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let red, green, blue: UInt64
        let alpha: Double
        switch hex.count {
        case 3:
            (alpha, red, green, blue) = (opacity, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (alpha, red, green, blue) = (opacity, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (alpha, red, green, blue) = (Double((int >> 24) / 255), int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (1, 1, 1, 1)
        }

        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: alpha
        )
    }

    // MARK: - SpiceMonk Design System Colors
    static let spicePrimary = Color(hex: "#0E8A4C")
    static let spicePrimaryDark = Color(hex: "#0A6B3B")
    static let spicePrimaryLight = Color(hex: "#E6F4EC")
    static let spiceTransit = Color(hex: "#1B57D6")
    static let spiceTransitLight = Color(hex: "#E8EEFC")
    static let spiceDue = Color(hex: "#C8322B")
    static let spiceDueLight = Color(hex: "#FBE3E1")
    static let spiceAmber = Color(hex: "#A85B08")
    static let spiceAmberLight = Color(hex: "#FDF0DC")
    static let spiceInk = Color(hex: "#0E1418")
    static let spiceMuted = Color(hex: "#69716A")
    static let spiceLightGray = Color(hex: "#EEF0EC")
    static let spiceBackground = Color(hex: "#F6F7F5")
    static let spiceCardBorder = Color(hex: "#E5E8E2")
    static let spiceDivider = Color(hex: "#EEF0EC")
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat((rgbValue & 0x0000FF) >> 0) / 255.0,
            alpha: CGFloat(alpha)
        )
    }

    static let spicePrimary = UIColor(hex: "#0E8A4C")
    static let spicePrimaryDark = UIColor(hex: "#0A6B3B")
    static let spiceTransit = UIColor(hex: "#1B57D6")
    static let spiceDue = UIColor(hex: "#C8322B")
    static let spiceAmber = UIColor(hex: "#A85B08")
    static let spiceInk = UIColor(hex: "#0E1418")
    static let spiceMuted = UIColor(hex: "#69716A")
    static let spiceBackground = UIColor(hex: "#F6F7F5")
}

