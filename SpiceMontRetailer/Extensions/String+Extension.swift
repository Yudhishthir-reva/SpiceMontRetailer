//
//  String+Extension.swift
//  SpiceMonk
//

import Foundation
import SwiftUI

extension String {
    var trim: String {
        trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    var isEmptyString: Bool {
        trim.isEmpty
    }

    var priceLabel: String {
        let trimmedString = trim
        return trimmedString.hasPrefix("₹") ? trimmedString : "₹\(trimmedString.removeZerosFromEnd(max: 2))"
    }

    var priceString: String {
        self
    }

    func removeZerosFromEnd(min minDigitAfterDecimal: Int = 0, max maxDigitAfterDecimal: Int = 2) -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: Double(self) ?? 0.0)
        formatter.minimumFractionDigits = minDigitAfterDecimal
        formatter.maximumFractionDigits = maxDigitAfterDecimal
        return String(formatter.string(from: number) ?? "")
    }

    func isValidIndianMobileNumber() -> Bool {
        let pattern = "^[6-9]\\d{9}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: utf16.count)

        if let match = regex?.firstMatch(in: self, options: [], range: range) {
            return match.range.length == utf16.count
        }
        return false
    }

    func isValidGSTNumber() -> Bool {
        let clean = self.trim.uppercased()
        guard clean.count == 15 else { return false }
        let pattern = "^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: clean.utf16.count)

        if let match = regex?.firstMatch(in: clean, options: [], range: range) {
            return match.range.length == clean.utf16.count
        }
        return false
    }

    var hexToColor: Color {
        Color(hex: self)
    }

    /// Sanitizes decimal input for positive weights/quantities (e.g. Kg):
    /// - Strips negative signs, spaces, letters, and special symbols
    /// - Allows only ONE decimal point '.'
    /// - Caps maximum decimal places (default 1, e.g. 1.2 kg)
    /// - Removes leading duplicate zeros
    func sanitizedDecimalQuantity(maxDecimalPlaces: Int = 1) -> String {
        var result = ""
        var hasDot = false
        var decimalCount = 0

        for char in self {
            if char.isNumber {
                if hasDot {
                    if decimalCount < maxDecimalPlaces {
                        result.append(char)
                        decimalCount += 1
                    }
                } else {
                    if result == "0" {
                        result = String(char)
                    } else {
                        result.append(char)
                    }
                }
            } else if (char == "." || char == ",") && !hasDot {
                if result.isEmpty {
                    result = "0."
                } else {
                    result.append(".")
                }
                hasDot = true
            }
        }
        return result
    }

    /// Sanitizes integer input for positive packet counts (e.g. Pkt):
    /// - Strips negative signs, decimals, spaces, letters, and special symbols
    /// - Allows only 0-9 digits up to maxDigits
    func sanitizedIntegerQuantity(maxDigits: Int = 5) -> String {
        var result = ""
        for char in self {
            if char.isNumber {
                if result == "0" {
                    result = String(char)
                } else if result.count < maxDigits {
                    result.append(char)
                }
            }
        }
        return result
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }

    init(milliseconds: Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        calendar.component(component, from: self)
    }
}
