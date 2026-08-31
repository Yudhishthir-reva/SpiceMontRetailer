//
//  UPIPaymentManager.swift
//  SpiceMontRetailer
//
//  Created on 31/08/26.
//

import SwiftUI
import UIKit

public struct UPIApp: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let shortName: String
    public let checkURLStrings: [String]
    public let basePaymentURLs: [String]
    public let brandColorHex: String
    public let bgTintHex: String
    public let systemIcon: String
    public let isGeneric: Bool

    public var brandColor: Color {
        Color(hex: brandColorHex)
    }

    public var bgTintColor: Color {
        Color(hex: bgTintHex)
    }

    public var isInstalled: Bool {
        if isGeneric { return true }
        for checkString in checkURLStrings {
            if let url = URL(string: checkString), UIApplication.shared.canOpenURL(url) {
                return true
            }
        }
        return false
    }

    public func buildPaymentURLs(
        upiId: String,
        payeeName: String,
        amount: Double?,
        note: String?
    ) -> [URL] {
        var urls: [URL] = []
        let sanitizedUPI = upiId.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedName = payeeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        for baseURLString in basePaymentURLs {
            guard var components = URLComponents(string: baseURLString) else { continue }
            
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "pa", value: sanitizedUPI),
                URLQueryItem(name: "pn", value: sanitizedName.isEmpty ? "SpiceMonk" : sanitizedName),
                URLQueryItem(name: "cu", value: "INR")
            ]

            if let amount = amount, amount > 0 {
                queryItems.append(URLQueryItem(name: "am", value: String(format: "%.2f", amount)))
            }

            if !sanitizedNote.isEmpty {
                queryItems.append(URLQueryItem(name: "tn", value: sanitizedNote))
            }

            components.queryItems = queryItems
            if let url = components.url {
                urls.append(url)
            }
        }
        return urls
    }
}

public final class UPIPaymentManager {
    public static let shared = UPIPaymentManager()

    private init() {}

    /// Supported list of Indian UPI apps on iOS
    public let allSupportedApps: [UPIApp] = [
        UPIApp(
            id: "phonepe",
            name: "PhonePe",
            shortName: "PhonePe",
            checkURLStrings: ["phonepe://", "phonepe://pay"],
            basePaymentURLs: ["phonepe://pay", "phonepe://upi/pay"],
            brandColorHex: "#5F259F",
            bgTintHex: "#F4EFFF",
            systemIcon: "indianrupeesign.circle.fill",
            isGeneric: false
        ),
        UPIApp(
            id: "gpay",
            name: "Google Pay",
            shortName: "GPay",
            checkURLStrings: ["tez://", "gpay://"],
            basePaymentURLs: ["tez://upi/pay", "gpay://upi/pay"],
            brandColorHex: "#1A73E8",
            bgTintHex: "#E8F0FE",
            systemIcon: "g.circle.fill",
            isGeneric: false
        ),
        UPIApp(
            id: "paytm",
            name: "Paytm",
            shortName: "Paytm",
            checkURLStrings: ["paytmmp://", "paytm://"],
            basePaymentURLs: ["paytmmp://upi/pay", "paytm://upi/pay"],
            brandColorHex: "#00BAF2",
            bgTintHex: "#E1F7FF",
            systemIcon: "p.circle.fill",
            isGeneric: false
        ),
        UPIApp(
            id: "cred",
            name: "CRED",
            shortName: "CRED",
            checkURLStrings: ["credpay://", "cred://"],
            basePaymentURLs: ["credpay://upi/pay", "cred://upi/pay"],
            brandColorHex: "#1C1C1E",
            bgTintHex: "#F2F2F7",
            systemIcon: "c.circle.fill",
            isGeneric: false
        ),
        UPIApp(
            id: "bhim",
            name: "BHIM UPI",
            shortName: "BHIM",
            checkURLStrings: ["bhim://"],
            basePaymentURLs: ["bhim://upi/pay"],
            brandColorHex: "#007A3D",
            bgTintHex: "#E6F4EC",
            systemIcon: "b.circle.fill",
            isGeneric: false
        ),
        UPIApp(
            id: "amazonpay",
            name: "Amazon Pay",
            shortName: "Amazon",
            checkURLStrings: ["amazonpay://"],
            basePaymentURLs: ["amazonpay://upi/pay"],
            brandColorHex: "#FF9900",
            bgTintHex: "#FFF4E5",
            systemIcon: "a.circle.fill",
            isGeneric: false
        ),
        UPIApp(
            id: "mobikwik",
            name: "MobiKwik",
            shortName: "MobiKwik",
            checkURLStrings: ["mobikwik://"],
            basePaymentURLs: ["mobikwik://upi/pay"],
            brandColorHex: "#0070E0",
            bgTintHex: "#E5F2FF",
            systemIcon: "m.circle.fill",
            isGeneric: false
        ),
        UPIApp(
            id: "generic_upi",
            name: "Any UPI App",
            shortName: "Any UPI",
            checkURLStrings: ["upi://pay", "upi://"],
            basePaymentURLs: ["upi://pay"],
            brandColorHex: "#E63946",
            bgTintHex: "#FFEBEB",
            systemIcon: "qrcode.viewfinder",
            isGeneric: true
        )
    ]

    /// Detects all UPI apps installed on this iPhone
    public func getInstalledUPIApps() -> [UPIApp] {
        let detected = allSupportedApps.filter { !$0.isGeneric && $0.isInstalled }
        return detected
    }

    /// Gets available apps to display
    public func getDisplayableUPIApps() -> (apps: [UPIApp], hasDetectedInstalled: Bool) {
        let installed = getInstalledUPIApps()
        if !installed.isEmpty {
            var list = installed
            if let generic = allSupportedApps.first(where: { $0.isGeneric }) {
                list.append(generic)
            }
            return (list, true)
        } else {
            // Simulator or phone without detected UPI apps
            return (allSupportedApps, false)
        }
    }

    /// Attempts to open the selected UPI app with pre-filled amount, note, and payee UPI ID
    public func openPayment(
        app: UPIApp,
        upiId: String,
        payeeName: String,
        amount: Double?,
        note: String?,
        completion: @escaping (Bool) -> Void
    ) {
        let urls = app.buildPaymentURLs(
            upiId: upiId,
            payeeName: payeeName,
            amount: amount,
            note: note
        )

        guard !urls.isEmpty else {
            completion(false)
            return
        }

        func tryOpen(index: Int) {
            guard index < urls.count else {
                // Try fallback to generic UPI if not already generic
                if !app.isGeneric, let genericApp = self.allSupportedApps.first(where: { $0.isGeneric }) {
                    let genericURLs = genericApp.buildPaymentURLs(
                        upiId: upiId,
                        payeeName: payeeName,
                        amount: amount,
                        note: note
                    )
                    if let fallbackURL = genericURLs.first {
                        UIApplication.shared.open(fallbackURL, options: [:]) { success in
                            completion(success)
                        }
                        return
                    }
                }
                completion(false)
                return
            }

            let currentURL = urls[index]
            UIApplication.shared.open(currentURL, options: [:]) { success in
                if success {
                    completion(true)
                } else {
                    tryOpen(index: index + 1)
                }
            }
        }

        tryOpen(index: 0)
    }
}
