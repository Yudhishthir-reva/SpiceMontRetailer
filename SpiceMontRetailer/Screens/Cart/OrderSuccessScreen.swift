//
//  OrderSuccessScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI

struct OrderSuccessScreen: View {
    var orderNumber: String = "#SM10248"
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
                            SpiceKVRow(key: "Order Number", value: orderNumber, isMonoValue: true)
                            SpiceKVRow(key: "Order Date", value: orderDate, isMonoValue: true)
                            SpiceKVRow(key: "Total Items", value: "\(totalItems) products · \(totalUnits) units")
                            SpiceKVRow(key: "Total Amount", value: String(format: "₹%.2f", totalAmount), isMonoValue: true, valueColor: Color.spiceInk)
                            HStack {
                                Text("Status").font(.system(size: 12, weight: .semibold)).foregroundColor(Color.spiceMuted)
                                Spacer()
                                SpiceStatusBadge(status: "CONFIRMED")
                            }

                            Divider().padding(.vertical, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Delivery Address")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color.spiceMuted)
                                Text(deliveryAddress)
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(Color.spiceInk)
                                    .lineSpacing(3)
                            }
                        }
                    }

                    Spacer(minLength: 24)

                    // Action Buttons
                    VStack(spacing: 10) {
                        SpicePrimaryButton(title: "View Order") {
                            navigateToOrderDetail = true
                        }

                        SpiceOutlinedButton(title: "Track Order") {
                            navigateToTracking = true
                        }

                        Button(action: { dismiss() }) {
                            Text("Continue Shopping")
                                .font(.system(size: 12.5, weight: .heavy))
                                .foregroundColor(Color.spiceInk)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.spiceBackground)
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $navigateToOrderDetail) {
            OrderDetailScreen(orderId: orderNumber.replacingOccurrences(of: "#", with: ""))
        }
        .navigationDestination(isPresented: $navigateToTracking) {
            DeliveryTrackingScreen(orderNumber: orderNumber)
        }
    }
}
