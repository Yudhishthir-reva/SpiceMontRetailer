//
//  QRCodeGenerator.swift
//  SpiceMontRetailer
//
//  Created on 29/08/26.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

public struct QRCodeGenerator {
    private static let context = CIContext()
    private static let filter = CIFilter.qrCodeGenerator()

    public static func generateQRCode(from string: String, scale: CGFloat = 10) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)

        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }

    public static func generateUPIString(
        upiId: String,
        payeeName: String,
        amount: Double? = nil,
        note: String? = nil
    ) -> String {
        var components = URLComponents()
        components.scheme = "upi"
        components.host = "pay"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "pa", value: upiId),
            URLQueryItem(name: "pn", value: payeeName),
            URLQueryItem(name: "cu", value: "INR")
        ]

        if let amount = amount, amount > 0 {
            queryItems.append(URLQueryItem(name: "am", value: String(format: "%.2f", amount)))
        }

        if let note = note, !note.isEmpty {
            queryItems.append(URLQueryItem(name: "tn", value: note))
        }

        components.queryItems = queryItems
        return components.url?.absoluteString ?? "upi://pay?pa=\(upiId)&pn=\(payeeName)"
    }
}
