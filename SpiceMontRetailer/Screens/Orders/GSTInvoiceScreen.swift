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
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }

                Text("Invoice")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Button(action: {}) {
                    Text("Share")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            ScrollView {
                VStack(spacing: 12) {
                    // Header & Parties Card
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Tax Invoice")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Text(invoiceNumber)
                                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.spiceMuted)
                                }
                                Spacer()
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: [Color.spicePrimary, Color.spicePrimaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                    .overlay(Text("S").font(.system(size: 18, weight: .heavy)).foregroundColor(.white))
                            }

                            Divider()

                            HStack(alignment: .top, spacing: 14) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("SELLER")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundColor(Color.spiceMuted)
                                    Text("SpiceMonk Foods Pvt Ltd")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                    Text("Plot 22, MIDC Andheri, Mumbai — 400093")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.spiceMuted)
                                    Text("GSTIN 27AAACS1234K1Z9")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.spiceInk)
                                }

                                Spacer()

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("BILL TO")
                                        .font(.system(size: 9.5, weight: .bold))
                                        .foregroundColor(Color.spiceMuted)
                                    Text("ABC General Store")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                    Text("Shop 14, Krishna Market, Mumbai — 400069")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.spiceMuted)
                                    Text("GSTIN 27ABCDE1234F1Z5")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.spiceInk)
                                }
                            }

                            Divider()

                            HStack {
                                Text("Invoice Date · \(invoiceDate)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.spiceMuted)
                                Spacer()
                                Text("Order · \(orderNumber)")
                                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.spiceMuted)
                            }
                        }
                    }

                    // Itemized Table Card
                    SpiceCard(padding: 0) {
                        VStack(spacing: 0) {
                            HStack {
                                Text("ITEM").frame(maxWidth: .infinity, alignment: .leading)
                                Text("QTY").frame(width: 32, alignment: .trailing)
                                Text("RATE").frame(width: 60, alignment: .trailing)
                                Text("TOTAL").frame(width: 68, alignment: .trailing)
                            }
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.spiceLightGray.opacity(0.6))

                            Divider()

                            invoiceItemRow(name: "Deggi Mirch Powder 100 g", hsn: "09042110 · GST 5%", qty: 4, rate: 78.40, total: 297.92)
                            Divider()
                            invoiceItemRow(name: "Kitchen King Masala 200 g", hsn: "09109100 · GST 5%", qty: 8, rate: 196.00, total: 1568.00)
                            Divider()
                            invoiceItemRow(name: "Chana Masala 100 g", hsn: "09109100 · GST 5%", qty: 10, rate: 64.00, total: 640.00)
                        }
                    }

                    // Total Calculation Card
                    SpiceCard {
                        VStack(spacing: 7) {
                            SpiceKVRow(key: "Subtotal", value: "₹10,240.00", isMonoValue: true)
                            SpiceKVRow(key: "Discount", value: "− ₹1,536.00", isMonoValue: true, valueColor: Color.spicePrimary)
                            SpiceKVRow(key: "Scheme Discount", value: "− ₹658.00", isMonoValue: true, valueColor: Color.spicePrimary)
                            SpiceKVRow(key: "Delivery Charges", value: "₹0.00", isMonoValue: true)
                            SpiceKVRow(key: "CGST 2.5%", value: "₹202.00", isMonoValue: true)
                            SpiceKVRow(key: "SGST 2.5%", value: "₹202.00", isMonoValue: true)
                            Divider().padding(.vertical, 2)
                            HStack {
                                Text("Grand Total")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)
                                Spacer()
                                Text("₹8,450.00")
                                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
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
        .navigationBarHidden(true)
    }

    private func invoiceItemRow(name: String, hsn: String, qty: Int, rate: Double, total: Double) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                Text(hsn)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.spiceMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(qty)")
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .frame(width: 32, alignment: .trailing)

            Text(String(format: "%.2f", rate))
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .frame(width: 60, alignment: .trailing)

            Text(String(format: "%.2f", total))
                .font(.system(size: 10.5, weight: .heavy, design: .monospaced))
                .frame(width: 68, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
