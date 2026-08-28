//
//  GSTInvoiceScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI

struct GSTInvoiceScreen: View {
    var invoiceNumber: String = "INV-2026-0468"
    var orderNumber: String = "#SM10245"
    var invoiceDate: String = "17 Aug 2026"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    // Header & Parties Card
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tax Invoice")
                                        .font(.appFont(size: 14, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Text(invoiceNumber)
                                        .font(.appFont(size: 11.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.spiceMuted)
                                }
                                Spacer()
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [Color.spicePrimary, Color.spicePrimaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                    .overlay(Text("S").font(.appFont(size: 18, weight: .heavy)).foregroundColor(.white))
                            }

                            Divider()

                            HStack(alignment: .top, spacing: 14) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("SELLER")
                                        .font(.appFont(size: 9.5, weight: .bold))
                                        .foregroundColor(Color.spiceMuted)
                                    Text("SPICEMONK INDIA PVT LTD")
                                        .font(.appFont(size: 11, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Text("GSTIN: 27AAACS1429B1ZB")
                                        .font(.appFont(size: 9.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(Color.spiceMuted)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 3) {
                                    Text("BUYER")
                                        .font(.appFont(size: 9.5, weight: .bold))
                                        .foregroundColor(Color.spiceMuted)
                                    Text("Sharma Kirana Store")
                                        .font(.appFont(size: 11, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Text("GSTIN: 27AABCS1234F1Z5")
                                        .font(.appFont(size: 9.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(Color.spiceMuted)
                                }
                            }
                        }
                    }

                    // Line Items Card
                    SpiceCard(padding: 0) {
                        VStack(spacing: 0) {
                            // Header Row
                            HStack {
                                Text("ITEM")
                                    .font(.appFont(size: 9.5, weight: .heavy))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("QTY")
                                    .font(.appFont(size: 9.5, weight: .heavy))
                                    .frame(width: 32, alignment: .trailing)
                                Text("RATE")
                                    .font(.appFont(size: 9.5, weight: .heavy))
                                    .frame(width: 60, alignment: .trailing)
                                Text("TOTAL")
                                    .font(.appFont(size: 9.5, weight: .heavy))
                                    .frame(width: 68, alignment: .trailing)
                            }
                            .foregroundColor(Color.spiceMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.spiceLightGray.opacity(0.6))

                            Divider().background(Color.spiceDivider)

                            invoiceItemRow(name: "Turmeric Powder 500g", hsn: "0910.30", qty: 20, rate: 120.00, total: 2400.00)
                            Divider().background(Color.spiceDivider)
                            invoiceItemRow(name: "Red Chilli Powder 1kg", hsn: "0904.20", qty: 10, rate: 280.00, total: 2800.00)
                            Divider().background(Color.spiceDivider)
                            invoiceItemRow(name: "Coriander Powder 500g", hsn: "0909.20", qty: 15, rate: 110.00, total: 1650.00)
                            Divider().background(Color.spiceDivider)
                            invoiceItemRow(name: "Garam Masala 200g", hsn: "0910.99", qty: 10, rate: 160.00, total: 1600.00)
                        }
                    }

                    // Tax & Total Summary Card
                    SpiceCard {
                        VStack(spacing: 7) {
                            SpiceKVRow(key: "Taxable Value", value: "₹8,047.62", isMonoValue: true)
                            SpiceKVRow(key: "CGST (2.5%)", value: "₹201.19", isMonoValue: true)
                            SpiceKVRow(key: "SGST (2.5%)", value: "₹201.19", isMonoValue: true)
                            Divider()
                            HStack {
                                Text("Invoice Total")
                                    .font(.appFont(size: 13, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)
                                Spacer()
                                Text("₹8,450.00")
                                    .font(.appFont(size: 16, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.spiceInk)
                            }
                        }
                    }

                    // Download Button
                    SpicePrimaryButton(title: "Download Invoice", height: 48) {}
                }
                .padding(16)
            }
            .background(Color.spiceBackground)
        }
        .navigationTitle("Tax Invoice")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private func invoiceItemRow(name: String, hsn: String, qty: Int, rate: Double, total: Double) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.appFont(size: 11, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                Text(hsn)
                    .font(.appFont(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.spiceMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(qty)")
                .font(.appFont(size: 10.5, weight: .semibold, design: .monospaced))
                .frame(width: 32, alignment: .trailing)

            Text(String(format: "%.2f", rate))
                .font(.appFont(size: 10.5, weight: .semibold, design: .monospaced))
                .frame(width: 60, alignment: .trailing)

            Text(String(format: "%.2f", total))
                .font(.appFont(size: 10.5, weight: .heavy, design: .monospaced))
                .frame(width: 68, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
