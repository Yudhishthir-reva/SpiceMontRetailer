//
//  MakePaymentScreen.swift
//  SpiceMontRetailer
//
//  Created on 29/08/26.
//

import SwiftUI
import UIKit

struct MakePaymentScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var configManager = AppConfigManager.shared

    var outstandingAmount: String? = nil

    @State private var amountText: String = "25748.00"
    @State private var noteText: String = ""
    @State private var isShowingSubmitRequestSheet: Bool = false
    @State private var isShowingToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var generatedQRImage: UIImage? = nil

    // Dynamic UPI Apps
    @State private var availableUPIApps: [UPIApp] = []
    @State private var selectedUPIApp: UPIApp? = nil
    @State private var hasDetectedInstalledApps: Bool = false

    // Fallbacks if config hasn't loaded yet
    private var upiId: String {
        configManager.accountDetails?.upiId?.isEmpty == false
            ? configManager.accountDetails!.upiId!
            : "7737772424@ybl"
    }

    private var accountName: String {
        configManager.accountDetails?.accountName?.isEmpty == false
            ? configManager.accountDetails!.accountName!
            : "Arjun"
    }

    private var bankName: String {
        configManager.accountDetails?.bankName?.isEmpty == false
            ? configManager.accountDetails!.bankName!
            : "Aavas Financiers Ltd"
    }

    private var ifscCode: String {
        configManager.accountDetails?.ifscCode?.isEmpty == false
            ? configManager.accountDetails!.ifscCode!
            : "af195"
    }

    private var branchName: String {
        configManager.accountDetails?.branchName?.isEmpty == false
            ? configManager.accountDetails!.branchName!
            : "Mansarovar"
    }

    private var qrCodeImageURL: String? {
        configManager.accountDetails?.qrCode
    }

    private var currentAmountDouble: Double {
        Double(amountText.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var formattedOutstandingBalance: String {
        if let out = outstandingAmount, !out.isEmpty {
            return out.hasPrefix("₹") ? out : "₹\(out)"
        }
        return "₹25,748.00"
    }

    var body: some View {
        ZStack {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Custom Header
                customNavigationBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // MARK: - 1. AMOUNT TO PAY Card
                        amountToPayCard

                        // MARK: - 2. PAY USING Card (Dynamic UPI Apps)
                        payUsingCard

                        // MARK: - 3. Pay Action Button
                        payActionButton

                        // MARK: - 4. UPI ID Card
                        upiIdCard

                        // MARK: - 5. SCAN TO PAY Card
                        scanToPayCard

                        // MARK: - 6. BANK TRANSFER Card
                        bankTransferCard

                        // MARK: - 7. Already Paid CTA Button
                        alreadyPaidButton

                        // MARK: - 8. Footer Note
                        footerNoteView

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            configManager.checkStatus()
            setupInitialValues()
            refreshUPIApps()
        }
        .sheet(isPresented: $isShowingSubmitRequestSheet) {
            SubmitPaymentRequestSheet(
                defaultAmount: currentAmountDouble > 0 ? currentAmountDouble : nil,
                defaultMessage: noteText.isEmpty ? "" : "Payment from \(noteText)"
            )
        }
        .toast(isPresenting: $isShowingToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Header
    private var customNavigationBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                    .frame(width: 38, height: 38)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.spiceCardBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text("Make Payment")
                    .font(.appFont(size: 16.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text("Pay SpiceMonk by UPI, QR or bank transfer")
                    .font(.appFont(size: 11.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color.spiceBackground)
    }

    // MARK: - 1. AMOUNT TO PAY Card
    private var amountToPayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AMOUNT TO PAY")
                .font(.appFont(size: 10.5, weight: .heavy))
                .foregroundColor(Color.spiceMuted)
                .tracking(0.5)

            // Amount Input Field
            HStack(spacing: 8) {
                Text("₹")
                    .font(.appFont(size: 20, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                TextField("0.00", text: $amountText)
                    .font(.appFont(size: 20, weight: .heavy, design: .rounded))
                    .keyboardType(.decimalPad)
                    .foregroundColor(Color.spiceInk)
                    .tint(Color.spicePrimary)
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.spiceCardBorder, lineWidth: 1)
            )

            // Outstanding Balance Label
            Text("Outstanding balance \(formattedOutstandingBalance)")
                .font(.appFont(size: 11.5, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .padding(.top, 2)

            // Note for SpiceMonk
            Text("Note for SpiceMonk")
                .font(.appFont(size: 11, weight: .bold))
                .foregroundColor(Color.spiceMuted)
                .padding(.top, 6)

            TextField("Name / Note", text: $noteText)
                .font(.appFont(size: 14, weight: .medium))
                .foregroundColor(Color.spiceInk)
                .tint(Color.spicePrimary)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.spiceCardBorder, lineWidth: 1)
                )

            Text("Sent with the payment so your account can be identified.")
                .font(.appFont(size: 11, weight: .medium))
                .foregroundColor(Color.spiceMuted)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - 2. PAY USING Card (Dynamic UPI App Selection)
    private var payUsingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("PAY USING")
                    .font(.appFont(size: 10.5, weight: .heavy))
                    .foregroundColor(Color.spiceMuted)
                    .tracking(0.5)

                Spacer()

                if hasDetectedInstalledApps {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "#10B981"))
                            .frame(width: 6, height: 6)

                        Text("Installed on this iPhone")
                            .font(.appFont(size: 10.5, weight: .bold))
                            .foregroundColor(Color(hex: "#10B981"))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#E6F4EC"))
                    .cornerRadius(8)
                }
            }

            // Horizontal scrolling list of detected/supported UPI apps
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableUPIApps) { app in
                        let isSelected = (selectedUPIApp?.id == app.id)
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedUPIApp = app
                            }
                        }) {
                            VStack(spacing: 6) {
                                UPIAppIconBadgeView(app: app, isSelected: isSelected)

                                Text(app.shortName)
                                    .font(.appFont(size: 11, weight: isSelected ? .heavy : .medium))
                                    .foregroundColor(isSelected ? app.brandColor : Color.spiceInk)
                                    .lineLimit(1)
                            }
                            .frame(width: 72)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.top, 4)
                .padding(.bottom, 2)
            }

            // Helper text
            if let selected = selectedUPIApp {
                Text("Pre-fills amount ₹\(amountText.isEmpty ? "0.00" : amountText) and note in \(selected.name).")
                    .font(.appFont(size: 11, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - 3. Pay Action Button
    private var payActionButton: some View {
        Button(action: handlePayAction) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pay ₹\(amountText.isEmpty ? "0.00" : amountText)")
                        .font(.appFont(size: 15.5, weight: .heavy))
                        .foregroundColor(.white)

                    Text("Opens \(selectedUPIApp?.name ?? "UPI App") directly")
                        .font(.appFont(size: 11.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(selectedUPIApp?.brandColor ?? Color.spicePrimary)
            .cornerRadius(14)
            .animation(.easeInOut(duration: 0.2), value: selectedUPIApp?.id)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. UPI ID Card
    private var upiIdCard: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.spicePrimaryLight)
                    .frame(width: 36, height: 36)

                Image(systemName: "qrcode")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.spicePrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("UPI ID")
                    .font(.appFont(size: 10.5, weight: .heavy))
                    .foregroundColor(Color.spiceMuted)

                Text(upiId)
                    .font(.appFont(size: 13.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }

            Spacer()

            Button(action: {
                UIPasteboard.general.string = upiId
                showToast("UPI ID copied: \(upiId)")
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.spicePrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.spicePrimaryLight.opacity(0.6))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - 5. SCAN TO PAY Card
    private var scanToPayCard: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("SCAN TO PAY")
                        .font(.appFont(size: 10.5, weight: .heavy))
                        .foregroundColor(Color.spiceMuted)
                        .tracking(0.5)
                    Spacer()
                }

                Text("Open any UPI app and scan this code.")
                    .font(.appFont(size: 12, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }

            // QR Code Display
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: "#FAFAF9"))
                    .frame(width: 220, height: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.spiceCardBorder, lineWidth: 1)
                    )

                if let qrUrl = qrCodeImageURL, !qrUrl.isEmpty {
                    RemoteImage(url: qrUrl, contentMode: .fit)
                        .frame(width: 190, height: 190)
                        .cornerRadius(8)
                } else if let qr = generatedQRImage {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 190, height: 190)
                        .cornerRadius(8)
                } else {
                    ProgressView()
                }
            }
            .padding(.vertical, 8)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - 6. BANK TRANSFER Card
    private var bankTransferCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.spiceInk)

                Text("BANK TRANSFER")
                    .font(.appFont(size: 11, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                    .tracking(0.5)

                Spacer()
            }

            Divider().background(Color.spiceDivider)

            // Rows
            bankRow(label: "Account Name", value: accountName)
            bankRow(label: "Bank", value: bankName)

            // IFSC with Copy
            HStack {
                Text("IFSC")
                    .font(.appFont(size: 12.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .frame(width: 100, alignment: .leading)

                Text(ifscCode)
                    .font(.appFont(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Button(action: {
                    UIPasteboard.general.string = ifscCode
                    showToast("IFSC copied: \(ifscCode)")
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.spicePrimary)
                }
                .buttonStyle(.plain)
            }

            bankRow(label: "Branch", value: branchName)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func bankRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.appFont(size: 12.5, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .frame(width: 100, alignment: .leading)

            Text(value)
                .font(.appFont(size: 13, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            Spacer()
        }
    }

    // MARK: - 7. Already Paid CTA Button
    private var alreadyPaidButton: some View {
        Button(action: {
            isShowingSubmitRequestSheet = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16, weight: .bold))

                Text("Already paid? Send the details")
                    .font(.appFont(size: 14, weight: .heavy))
            }
            .foregroundColor(Color.spicePrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.spicePrimary, lineWidth: 1.5)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 8. Footer Note
    private var footerNoteView: some View {
        Text("Payments are confirmed by the SpiceMonk team. Your ledger updates once the payment is approved.")
            .font(.appFont(size: 11.5, weight: .medium))
            .foregroundColor(Color.spiceMuted)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.top, 4)
    }

    // MARK: - Helper Methods
    private func setupInitialValues() {
        if let out = outstandingAmount, !out.isEmpty {
            let cleaned = out.replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let d = Double(cleaned), d > 0 {
                amountText = String(format: "%.2f", d)
            }
        }

        let defaultName = UserDefaultManager.shared.getUserDefaultsString(key: .userName)
        if !defaultName.isEmpty {
            noteText = defaultName
        } else {
            noteText = "Ajay"
        }
    }

    private func refreshUPIApps() {
        let (apps, hasDetected) = UPIPaymentManager.shared.getDisplayableUPIApps()
        self.availableUPIApps = apps
        self.hasDetectedInstalledApps = hasDetected
        if self.selectedUPIApp == nil || !apps.contains(where: { $0.id == selectedUPIApp?.id }) {
            self.selectedUPIApp = apps.first
        }
    }

    private func generateQR() {
        let amount = currentAmountDouble
        let upiLink = QRCodeGenerator.generateUPIString(
            upiId: upiId,
            payeeName: accountName,
            amount: amount > 0 ? amount : nil,
            note: noteText.isEmpty ? "SpiceMonk" : noteText
        )
        self.generatedQRImage = QRCodeGenerator.generateQRCode(from: upiLink, scale: 12)
    }

    private func handlePayAction() {
        guard let app = selectedUPIApp ?? availableUPIApps.first else {
            // Fallback generic UPI
            fallbackGenericUPI()
            return
        }

        let amount = currentAmountDouble
        let note = noteText.isEmpty ? "SpiceMonk" : noteText

        UPIPaymentManager.shared.openPayment(
            app: app,
            upiId: upiId,
            payeeName: accountName,
            amount: amount > 0 ? amount : nil,
            note: note
        ) { success in
            if !success {
                UIPasteboard.general.string = upiId
                showToast("\(app.name) couldn't be opened directly. UPI ID copied: \(upiId)")
            }
        }
    }

    private func fallbackGenericUPI() {
        let amount = currentAmountDouble
        let upiLink = QRCodeGenerator.generateUPIString(
            upiId: upiId,
            payeeName: accountName,
            amount: amount > 0 ? amount : nil,
            note: noteText.isEmpty ? "SpiceMonk" : noteText
        )

        if let url = URL(string: upiLink), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            UIPasteboard.general.string = upiId
            showToast("UPI ID copied! Please complete payment in your UPI app.")
        }
    }

    private func showToast(_ message: String) {
        self.toastMessage = message
        self.isShowingToast = true
    }
}

// MARK: - UPI App Icon Badge View
struct UPIAppIconBadgeView: View {
    let app: UPIApp
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(app.bgTintColor)
                .frame(width: 56, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? app.brandColor : Color.spiceCardBorder, lineWidth: isSelected ? 2.5 : 1)
                )
                .shadow(color: isSelected ? app.brandColor.opacity(0.2) : Color.clear, radius: 4, x: 0, y: 2)

            // Brand Typography / Icon
            brandIconContent
        }
        .overlay(
            Group {
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(app.brandColor)
                            .frame(width: 18, height: 18)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .offset(x: 24, y: -24)
                }
            }
        )
    }

    @ViewBuilder
    private var brandIconContent: some View {
        switch app.id {
        case "phonepe":
            Text("पे")
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(app.brandColor)

        case "gpay":
            VStack(spacing: -2) {
                Text("G")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(Color(hex: "#4285F4"))
                Text("Pay")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "#5F6368"))
            }

        case "paytm":
            VStack(spacing: 0) {
                Text("Pay")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(Color(hex: "#002E6E"))
                Text("tm")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(Color(hex: "#00BAF2"))
            }

        case "cred":
            Text("CRED")
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(Color(hex: "#1C1C1E"))

        case "bhim":
            VStack(spacing: -1) {
                Text("BHIM")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(Color(hex: "#007A3D"))
                Text("UPI")
                    .font(.system(size: 8, weight: .heavy))
                    .foregroundColor(Color(hex: "#FF6600"))
            }

        case "amazonpay":
            VStack(spacing: 0) {
                Text("pay")
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(hex: "#FF9900"))
            }

        case "mobikwik":
            Text("Mobi")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "#0070E0"))

        default:
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(app.brandColor)
        }
    }
}

#Preview {
    MakePaymentScreen()
}
