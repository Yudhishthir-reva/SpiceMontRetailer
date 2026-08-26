//
//  UnitConverter.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import Foundation

public struct UnitConverter {
    /// Extracts packet weight in Kilograms from unit string like "50 gms", "100 gms", "200 gms", "500 gms", "1 KG"
    public static func weightInKg(from unitString: String?) -> Double {
        guard let raw = unitString?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return 0.1 // default 100g = 0.1 kg
        }

        // If unit contains "kg"
        if raw.contains("kg") {
            let numeric = raw.replacingOccurrences(of: "kg", with: "")
                .replacingOccurrences(of: " ", with: "")
            if let val = Double(numeric), val > 0 {
                return val
            }
            return 1.0
        }

        // If unit contains "gms" / "gm" / "g"
        let numeric = raw
            .replacingOccurrences(of: "gms", with: "")
            .replacingOccurrences(of: "gm", with: "")
            .replacingOccurrences(of: "g", with: "")
            .replacingOccurrences(of: " ", with: "")

        if let valInGrams = Double(numeric), valInGrams > 0 {
            return valInGrams / 1000.0
        }

        return 0.1
    }

    /// Converts KG to Packet count
    public static func kgToPkt(kg: Double, unit: String?) -> Int {
        guard kg > 0 else { return 0 }
        let weightPerPkt = weightInKg(from: unit)
        guard weightPerPkt > 0 else { return 0 }
        return Int(round(kg / weightPerPkt))
    }

    /// Converts Packet count to KG string
    public static func pktToKg(pkt: Int, unit: String?) -> String {
        guard pkt > 0 else { return "" }
        let weightPerPkt = weightInKg(from: unit)
        let totalKg = Double(pkt) * weightPerPkt
        if totalKg.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(totalKg))"
        } else {
            let formatted = String(format: "%.1f", totalKg)
            return formatted
                .replacingOccurrences(of: "0+$", with: "", options: .regularExpression)
                .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
        }
    }
}
