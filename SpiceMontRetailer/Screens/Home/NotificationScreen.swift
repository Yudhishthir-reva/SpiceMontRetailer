//
//  NotificationScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI

struct SpiceNotificationItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let time: String
    let isUnread: Bool
    let type: String // "order", "scheme", "account"
}

struct NotificationScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var notifications: [SpiceNotificationItem] = [
        SpiceNotificationItem(
            title: "Order Out for Delivery",
            message: "Order #SM10245 is out for delivery and expected today by 6:00 PM.",
            time: "Today, 9:12 AM",
            isUnread: true,
            type: "order"
        ),
        SpiceNotificationItem(
            title: "New Scheme Available",
            message: "MDH Bulk Purchase Scheme is now live for your account. Valid till 31 Aug.",
            time: "Today, 8:00 AM",
            isUnread: true,
            type: "scheme"
        ),
        SpiceNotificationItem(
            title: "Order Dispatched",
            message: "Order #SM10245 has been dispatched from the Andheri warehouse.",
            time: "Yesterday, 6:40 PM",
            isUnread: true,
            type: "order"
        ),
        SpiceNotificationItem(
            title: "Order Confirmed",
            message: "Order #SM10245 has been confirmed. 12 items · ₹8,450.00",
            time: "16 Aug, 11:02 AM",
            isUnread: false,
            type: "order"
        ),
        SpiceNotificationItem(
            title: "Registration Approved",
            message: "Your retailer account has been approved. You can now place orders.",
            time: "02 Aug, 4:15 PM",
            isUnread: false,
            type: "account"
        )
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(notifications) { item in
                    SpiceCard(padding: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(item.isUnread ? Color.spicePrimaryLight : Color.spiceLightGray)
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Image(systemName: item.type == "order" ? "shippingbox.fill" : (item.type == "scheme" ? "tag.fill" : "person.fill"))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(item.isUnread ? Color.spicePrimary : Color.spiceMuted)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(item.title)
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)

                                    Spacer()

                                    if item.isUnread {
                                        Circle()
                                            .fill(Color.spicePrimary)
                                            .frame(width: 7, height: 7)
                                    }
                                }

                                Text(item.message)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.spiceInk.opacity(0.85))
                                    .lineSpacing(2)

                                Text(item.time)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.spiceMuted)
                                    .padding(.top, 2)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.spiceBackground)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    for i in 0..<notifications.count {
                        notifications[i] = SpiceNotificationItem(
                            title: notifications[i].title,
                            message: notifications[i].message,
                            time: notifications[i].time,
                            isUnread: false,
                            type: notifications[i].type
                        )
                    }
                }) {
                    Text("Mark All Read")
                        .font(.system(size: 11.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }
        }
    }
}
