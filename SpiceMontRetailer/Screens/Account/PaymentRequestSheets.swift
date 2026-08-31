//
//  PaymentRequestSheets.swift
//  SpiceMontRetailer
//
//  Created on 29/08/26.
//

import SwiftUI

// MARK: - Submit Payment Request Sheet

struct SubmitPaymentRequestSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var requestManager = PaymentRequestManager.shared

    var defaultAmount: Double? = nil
    var defaultMessage: String = ""

    @State private var amountText: String = ""
    @State private var selectedMode: String = "UPI"
    @State private var referenceNumber: String = ""
    @State private var messageText: String = ""
    @State private var errorMessage: String = ""
    @State private var isSuccess: Bool = false

    private let paymentModes = ["UPI", "Bank Transfer", "Cash", "Cheque"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.spiceBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header info banner
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.spicePrimary)

                            Text("Enter your payment details below so our team can verify and credit your ledger.")
                                .font(.appFont(size: 12.5, weight: .medium))
                                .foregroundColor(Color.spiceInk.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .background(Color.spicePrimaryLight)
                        .cornerRadius(12)

                        // 1. Amount Input Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AMOUNT PAID")
                                .font(.appFont(size: 11, weight: .heavy))
                                .foregroundColor(Color.spiceMuted)
                                .tracking(0.5)

                            HStack(spacing: 8) {
                                Text("₹")
                                    .font(.appFont(size: 22, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)

                                TextField("0.00", text: $amountText)
                                    .font(.appFont(size: 22, weight: .heavy, design: .rounded))
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
                        }

                        // 2. Payment Mode Selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PAYMENT MODE")
                                .font(.appFont(size: 11, weight: .heavy))
                                .foregroundColor(Color.spiceMuted)
                                .tracking(0.5)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(paymentModes, id: \.self) { mode in
                                        Button(action: {
                                            selectedMode = mode
                                        }) {
                                            Text(mode)
                                                .font(.appFont(size: 13, weight: .bold))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(selectedMode == mode ? Color.spicePrimary : Color.white)
                                                .foregroundColor(selectedMode == mode ? .white : Color.spiceInk)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedMode == mode ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 1)
                            }
                        }

                        // 3. Reference / UTR Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TRANSACTION ID / UTR / CHEQUE NO.")
                                .font(.appFont(size: 11, weight: .heavy))
                                .foregroundColor(Color.spiceMuted)
                                .tracking(0.5)

                            TextField("e.g. 423987123456 or Cheque #", text: $referenceNumber)
                                .font(.appFont(size: 14, weight: .medium))
                                .foregroundColor(Color.spiceInk)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spiceCardBorder, lineWidth: 1)
                                )
                        }

                        // 4. Note / Message
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTE / REMARKS")
                                .font(.appFont(size: 11, weight: .heavy))
                                .foregroundColor(Color.spiceMuted)
                                .tracking(0.5)

                            TextField("e.g. Paid via PhonePe / Ajay Retailer", text: $messageText)
                                .font(.appFont(size: 14, weight: .medium))
                                .foregroundColor(Color.spiceInk)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spiceCardBorder, lineWidth: 1)
                                )
                        }

                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.appFont(size: 12.5, weight: .bold))
                                .foregroundColor(Color.spiceDue)
                                .padding(.horizontal, 4)
                        }

                        Spacer(minLength: 20)

                        // Submit Button
                        Button(action: submitRequest) {
                            HStack(spacing: 8) {
                                if requestManager.isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.appFont(size: 15, weight: .bold))
                                }
                                Text(requestManager.isSubmitting ? "Submitting..." : "Submit Payment Details")
                                    .font(.appFont(size: 14.5, weight: .heavy))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.spicePrimary)
                            .cornerRadius(12)
                        }
                        .disabled(requestManager.isSubmitting)
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Submit Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.appFont(size: 14, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                    }
                }
            }
            .onAppear {
                if let def = defaultAmount, def > 0 {
                    amountText = String(format: "%.2f", def)
                }
                if !defaultMessage.isEmpty {
                    messageText = defaultMessage
                } else {
                    let userName = UserDefaultManager.shared.getUserDefaultsString(key: .userName)
                    if !userName.isEmpty {
                        messageText = "Payment from \(userName)"
                    }
                }
            }
        }
    }

    private func submitRequest() {
        errorMessage = ""
        guard let amount = Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines)), amount > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        requestManager.submitRequest(
            amount: amount,
            message: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            paymentMode: selectedMode,
            referenceNumber: referenceNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        ) { success, msg in
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMessage = msg
            }
        }
    }
}

// MARK: - Payment Requests List Sheet

struct PaymentRequestsListSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var requestManager = PaymentRequestManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.spiceBackground.ignoresSafeArea()

                if requestManager.requests.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(Color.spiceMuted.opacity(0.6))

                        Text("No Requests Submitted")
                            .font(.appFont(size: 18, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text("Your submitted payment requests will appear here along with their verification status.")
                            .font(.appFont(size: 13, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(requestManager.requests) { req in
                                paymentRequestCard(item: req)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Payment Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.appFont(size: 14, weight: .heavy))
                    .foregroundColor(Color.spicePrimary)
                }
            }
            .onAppear {
                requestManager.fetchRemoteRequests()
            }
        }
    }

    @ViewBuilder
    private func paymentRequestCard(item: PaymentRequestSubmitData) -> some View {
        let status = item.statusText ?? (item.status == 1 ? "Approved" : (item.status == 2 ? "Rejected" : "Pending"))
        let isApproved = item.status == 1 || status.lowercased() == "approved"
        let isRejected = item.status == 2 || status.lowercased() == "rejected"
        let fallbackColorHex = isApproved ? "#0ab39c" : (isRejected ? "#f06548" : "#FFA500")
        let statusColorHex = (item.statusColor?.isEmpty == false) ? item.statusColor! : fallbackColorHex
        let statusColor = Color(hex: statusColorHex)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(String(format: "₹%.2f", item.amount ?? 0))
                    .font(.appFont(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Text(status.uppercased())
                    .font(.appFont(size: 10, weight: .heavy))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .cornerRadius(6)
            }

            if let mode = item.paymentMode, !mode.isEmpty {
                HStack(spacing: 6) {
                    Text("Mode:")
                        .font(.appFont(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    Text(mode)
                        .font(.appFont(size: 12.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    if let ref = item.referenceNumber, !ref.isEmpty {
                        Text("· Ref: \(ref)")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }
                }
            }

            if let msg = item.message, !msg.isEmpty {
                Text(msg)
                    .font(.appFont(size: 12.5, weight: .medium))
                    .foregroundColor(Color.spiceInk.opacity(0.85))
            }

            // Admin Remark (if any)
            if let remark = item.adminRemark, !remark.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: isApproved ? "checkmark.seal.fill" : (isRejected ? "exclamationmark.circle.fill" : "info.circle.fill"))
                        .font(.system(size: 13))
                        .foregroundColor(statusColor)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Admin Remark")
                            .font(.appFont(size: 10.5, weight: .bold))
                            .foregroundColor(statusColor)

                        Text(remark)
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceInk)
                    }
                }
                .padding(10)
                .background(statusColor.opacity(0.08))
                .cornerRadius(8)
            }

            // Attachment image preview (if any)
            if let attachmentUrl = item.attachment, !attachmentUrl.isEmpty, let url = URL(string: attachmentUrl) {
                HStack(spacing: 8) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.spicePrimary)

                    Text("Receipt Attached")
                        .font(.appFont(size: 12, weight: .semibold))
                        .foregroundColor(Color.spicePrimary)

                    Spacer()

                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipped()
                                .cornerRadius(6)
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.spiceCardBorder.opacity(0.5))
                                .frame(width: 40, height: 40)
                        }
                    }
                }
                .padding(8)
                .background(Color.spiceBackground)
                .cornerRadius(8)
            }

            Divider().background(Color.spiceDivider)

            HStack {
                Image(systemName: "clock")
                    .font(.appFont(size: 11, weight: .medium))
                    .foregroundColor(Color.spiceMuted)

                Text(item.createdAt ?? "Recently")
                    .font(.appFont(size: 11.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)

                Spacer()
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }
}
