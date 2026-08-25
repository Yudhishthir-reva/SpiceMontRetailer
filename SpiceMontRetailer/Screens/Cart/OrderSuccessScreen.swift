//
//  OrderSuccessScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI

struct OrderSuccessScreen: View {
    var orderId: Int? = nil
    var orderNumber: String = "#2026-27/2967"
    var orderDate: String = "Today, 9:41 AM"
    var totalAmount: Double = 957.60
    var totalItems: Int = 4
    var totalUnits: Int = 34
    var deliveryAddress: String = "ABC General Store, Shop 14, Krishna Market, Andheri East, Mumbai — 400069"

    @Environment(\.dismiss) private var dismiss
    @State private var navigateToOrderDetail: Bool = false
    @State private var navigateToTracking: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Spacer(minLength: 24)

                    // Success Icon
                    Circle()
                        .fill(Color.spicePrimary)
                        .frame(width: 74, height: 74)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        )

                    Text("Order Placed Successfully")
                        .font(.system(size: 21, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    Text("Your order has been sent to SpiceMonk for processing. You will be notified as the status changes.")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

                    // Summary Card
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(orderNumber)
                                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.spiceInk)
                                Spacer()
                                SpiceStatusBadge(status: "PLACED")
                            }

                            Divider()

                            SpiceKVRow(key: "Order Date", value: orderDate)
                            SpiceKVRow(key: "Total Amount", value: String(format: "₹%.2f", totalAmount), isMonoValue: true)
                            SpiceKVRow(key: "Items Count", value: "\(totalItems) products (\(totalUnits) units)")
                            SpiceKVRow(key: "Delivery To", value: deliveryAddress)
                        }
                    }

                    // Action Buttons
                    VStack(spacing: 10) {
                        SpicePrimaryButton(title: "Track Order", height: 48) {
                            navigateToTracking = true
                        }

                        SpiceOutlinedButton(title: "View Order Details", height: 48) {
                            navigateToOrderDetail = true
                        }

                        SpiceGhostButton(title: "Back to Home", height: 44) {
                            dismiss()
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color.spiceBackground)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToOrderDetail) {
            OrderDetailScreen(orderId: "\(orderId ?? 6434)")
        }
        .navigationDestination(isPresented: $navigateToTracking) {
            DeliveryTrackingScreen(orderId: orderId, orderNumber: orderNumber)
        }
    }
}
