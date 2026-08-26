//
//  SalesmanScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI

struct SalesmanScreen: View {
    @Environment(\.dismiss) private var dismiss
    private let defaults = UserDefaultManager.shared

    var salesmanName: String {
        defaults.getUserDefaultsString(key: .salesmanName)
    }

    var salesmanPhone: String {
        defaults.getUserDefaultsString(key: .salesmanPhone)
    }

    var sellerCode: String {
        defaults.getUserDefaultsString(key: .sellerId)
    }

    var body: some View {
        VStack(spacing: 0) {
            SpiceTopBar(title: "Assigned Salesman", showBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(spacing: 12) {
                    if !salesmanName.isEmpty || !salesmanPhone.isEmpty {
                        // Profile Card
                        SpiceCard {
                            VStack(spacing: 12) {
                                Circle()
                                    .fill(LinearGradient(colors: [Color(hex: "#1B57D6"), Color(hex: "#123A8E")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Text(String(salesmanName.prefix(2)).uppercased())
                                            .font(.system(size: 22, weight: .heavy))
                                            .foregroundColor(.white)
                                    )

                                VStack(spacing: 4) {
                                    Text(salesmanName)
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)

                                    if !salesmanPhone.isEmpty {
                                        Text(salesmanPhone)
                                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color.spiceInk)
                                    }

                                    SpiceStatusBadge(status: "MAPPED BY ADMIN")
                                        .padding(.top, 2)
                                }

                                if !sellerCode.isEmpty {
                                    Divider().padding(.vertical, 4)
                                    SpiceKVRow(key: "Retailer Code", value: sellerCode, isMonoValue: true)
                                }

                                if !salesmanPhone.isEmpty {
                                    SpicePrimaryButton(title: "Call Salesman", height: 46) {
                                        let cleanNumber = salesmanPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                                        if let url = URL(string: "tel://\(cleanNumber)") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        SpiceEmptyStateView(
                            title: "No Salesman Assigned",
                            message: "A salesman has not been mapped to your account yet.",
                            buttonTitle: "Go Back"
                        ) {
                            dismiss()
                        }
                        .padding(.top, 30)
                    }

                    // Mapping Note Card
                    SpiceCard(backgroundColor: Color.spiceLightGray.opacity(0.5), borderColor: Color.spiceCardBorder) {
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Color.spiceMuted).frame(width: 5, height: 5).padding(.top, 4)
                            Text("Salesman mapping is controlled by SpiceMonk admin and cannot be changed from the app.")
                                .font(.system(size: 10.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                                .lineSpacing(2)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.spiceBackground)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Customer Support Screen
struct CustomerSupportScreen: View {
    @Environment(\.dismiss) private var dismiss
    private let defaults = UserDefaultManager.shared

    var supportPhone: String {
        let ph = defaults.getUserDefaultsString(key: .customerSupportPhone)
        return !ph.isEmpty ? ph : "1800 200 4455"
    }

    var salesmanName: String {
        defaults.getUserDefaultsString(key: .salesmanName)
    }

    var salesmanPhone: String {
        defaults.getUserDefaultsString(key: .salesmanPhone)
    }

    var sellerCode: String {
        defaults.getUserDefaultsString(key: .sellerId)
    }

    var body: some View {
        VStack(spacing: 0) {
            SpiceTopBar(title: "Customer Support", showBack: true, onBack: { dismiss() })

            ScrollView {
                VStack(spacing: 12) {
                    // Toll-free Card
                    SpiceCard {
                        VStack(spacing: 14) {
                            Circle()
                                .fill(Color.spicePrimaryLight)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "headset")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundColor(Color.spicePrimary)
                                )

                            VStack(spacing: 4) {
                                Text("SpiceMonk Customer Care")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)

                                Text(supportPhone)
                                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.spicePrimary)

                                Text("Monday – Saturday · 9:00 AM to 7:00 PM")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                            }

                            SpicePrimaryButton(title: "Call Customer Support", height: 48) {
                                let clean = supportPhone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                                if let url = URL(string: "tel://\(clean)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    // Salesman shortcut
                    if !salesmanName.isEmpty {
                        NavigationLink(destination: SalesmanScreen()) {
                            SpiceCard {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color(hex: "#1B57D6"), Color(hex: "#123A8E")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 42, height: 42)
                                        .overlay(
                                            Text(String(salesmanName.prefix(2)).uppercased())
                                                .font(.system(size: 11, weight: .heavy))
                                                .foregroundColor(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(salesmanName)
                                            .font(.system(size: 12.5, weight: .heavy))
                                            .foregroundColor(Color.spiceInk)

                                        if !salesmanPhone.isEmpty {
                                            Text("Your salesman · \(salesmanPhone)")
                                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                                .foregroundColor(Color.spiceMuted)
                                        }
                                    }

                                    Spacer()

                                    Text("CALL")
                                        .font(.system(size: 9.5, weight: .heavy))
                                        .foregroundColor(Color.spicePrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.spicePrimaryLight)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Helper Note
                    if !sellerCode.isEmpty {
                        SpiceCard(backgroundColor: Color.spiceLightGray.opacity(0.5), borderColor: Color.spiceCardBorder) {
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(Color.spiceMuted).frame(width: 5, height: 5).padding(.top, 4)
                                Text("Keep your Retailer ID \(sellerCode) and order number ready when you call.")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                                    .lineSpacing(2)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.spiceBackground)
        }
        .navigationBarHidden(true)
    }
}
