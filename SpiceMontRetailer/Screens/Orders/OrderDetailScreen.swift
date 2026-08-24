//
//  OrderDetailScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct OrderDetailScreen: View {
    var orderId: String = "101"
    @Environment(\.dismiss) private var dismiss

    @State private var order: Order?
    @State private var isLoading: Bool = true
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var showCancelAlert: Bool = false

    private let service = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var intOrderId: Int {
        Int(orderId.replacingOccurrences(of: "#", with: "")) ?? 101
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }

                Text("Order Details")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                if let order = order {
                    NavigationLink(destination: GSTInvoiceScreen(invoiceNumber: "INV-\(order.id ?? intOrderId)", orderNumber: order.orderNumberFormatted)) {
                        Text("Invoice")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            if isLoading && order == nil {
                ScrollView {
                    VStack(spacing: 12) {
                        SpiceSkeletonBox(height: 120, cornerRadius: 16)
                        SpiceSkeletonBox(height: 160, cornerRadius: 16)
                        SpiceSkeletonBox(height: 200, cornerRadius: 16)
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            } else if let order = order {
                ScrollView {
                    VStack(spacing: 12) {
                        // Header Order Card
                        SpiceCard {
                            VStack(spacing: 8) {
                                HStack {
                                    Text(order.orderNumberFormatted)
                                        .font(.system(size: 14.5, weight: .heavy, design: .monospaced))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                    SpiceStatusBadge(status: order.statusLabel.uppercased())
                                }
                                Divider()
                                if let date = order.createdAt {
                                    SpiceKVRow(key: "Order Date", value: date, isMonoValue: true)
                                }
                                SpiceKVRow(key: "Total Items", value: "\(order.itemsCount ?? order.items?.count ?? 0) items")
                                SpiceKVRow(key: "Total Amount", value: order.total?.priceLabel ?? "₹0", isMonoValue: true)
                            }
                        }

                        // Status Timeline Card
                        if let timeline = order.timeline, !timeline.isEmpty {
                            SpiceCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Status Timeline")
                                        .font(.system(size: 12.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)

                                    ForEach(Array(timeline.enumerated()), id: \.offset) { index, item in
                                        timelineStep(
                                            title: item.label ?? "",
                                            time: item.date ?? "",
                                            isCompleted: item.isDone == true,
                                            isCurrent: item.isActive == true,
                                            isLast: index == timeline.count - 1
                                        )
                                    }
                                }
                            }
                        }

                        // Order Items
                        SpiceCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Order Items (\(order.items?.count ?? 0))")
                                        .font(.system(size: 12.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                }

                                Divider()

                                ForEach(order.items ?? []) { item in
                                    HStack(alignment: .top, spacing: 10) {
                                        if let img = item.productImage, !img.isEmpty {
                                            RemoteImage(url: img)
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 7))
                                        } else {
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(LinearGradient(colors: [Color(hex: "#B8702F"), Color(hex: "#6E3A15")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(width: 44, height: 44)
                                                .overlay(Text("ITEM").font(.system(size: 8, weight: .heavy)).foregroundColor(.white))
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.productName ?? "Product")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(Color.spiceInk)
                                            Text("\(item.unit ?? "") · \(item.quantity ?? 1) units × \(item.price?.priceLabel ?? "₹0")")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(Color.spiceMuted)
                                        }

                                        Spacer()

                                        Text(item.totalPrice?.priceLabel ?? item.price?.priceLabel ?? "₹0")
                                            .font(.system(size: 12.5, weight: .heavy, design: .monospaced))
                                            .foregroundColor(Color.spiceInk)
                                    }
                                    if item.id != order.items?.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }

                        // Delivery Address Card
                        if let address = order.address {
                            SpiceCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Delivery Address")
                                        .font(.system(size: 12.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Text(address.name ?? "")
                                        .font(.system(size: 12, weight: .bold))
                                    Text(address.fullAddress)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(Color.spiceMuted)
                                    if let phone = address.phone, !phone.isEmpty {
                                        Text(phone)
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundColor(Color.spiceMuted)
                                    }
                                }
                            }
                        }

                        // Bill Summary Card
                        SpiceCard {
                            VStack(spacing: 7) {
                                HStack {
                                    Text("Bill Summary")
                                        .font(.system(size: 12.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                }
                                Divider()
                                SpiceKVRow(key: "Product Total", value: order.subtotal?.priceLabel ?? "₹0", isMonoValue: true)
                                if let d = order.discount, Double(d) ?? 0 > 0 {
                                    SpiceKVRow(key: "Product Discount", value: "− \(d.priceLabel)", isMonoValue: true, valueColor: Color.spicePrimary)
                                }
                                SpiceKVRow(key: "Delivery Charges", value: Double(order.deliveryCharge ?? "0") ?? 0 > 0 ? (order.deliveryCharge?.priceLabel ?? "₹0") : "FREE", isMonoValue: true)
                                Divider().padding(.vertical, 2)
                                HStack {
                                    Text("Final Order Amount")
                                        .font(.system(size: 13.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                    Text(order.total?.priceLabel ?? "₹0")
                                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                                        .foregroundColor(Color.spiceInk)
                                }
                            }
                        }

                        // Action Buttons
                        VStack(spacing: 8) {
                            NavigationLink(destination: DeliveryTrackingScreen(orderNumber: order.orderNumberFormatted)) {
                                Text("Track Order")
                                    .font(.system(size: 14.5, weight: .heavy))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.spicePrimary)
                                    .cornerRadius(12)
                            }

                            HStack(spacing: 8) {
                                NavigationLink(destination: GSTInvoiceScreen(invoiceNumber: "INV-\(order.id ?? intOrderId)", orderNumber: order.orderNumberFormatted)) {
                                    Text("View Invoice")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 38)
                                        .background(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))
                                        .cornerRadius(8)
                                }

                                NavigationLink(destination: SalesmanScreen()) {
                                    Text("Call Salesman")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 38)
                                        .background(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            }
        }
        .onAppear {
            loadOrderDetail()
        }
        .navigationBarHidden(true)
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    private func loadOrderDetail() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        service.fetchOrderDetail(id: intOrderId, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                self.order = response.order
            }
            .store(in: &cancellables)
    }

    private func timelineStep(title: String, time: String, isCompleted: Bool, isCurrent: Bool, isLast: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                if isCompleted {
                    Circle().fill(Color.spicePrimary).frame(width: 11, height: 11)
                } else if isCurrent {
                    Circle().stroke(Color.spiceTransit, lineWidth: 3).background(Circle().fill(Color.white)).frame(width: 12, height: 12)
                } else {
                    Circle().stroke(Color.spiceMuted.opacity(0.4), lineWidth: 1.5).frame(width: 10, height: 10)
                }

                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.spicePrimary : Color.spiceCardBorder)
                        .frame(width: 2, height: 22)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11.5, weight: isCurrent ? .heavy : .bold))
                    .foregroundColor(isCurrent ? Color.spiceTransit : (isCompleted ? Color.spiceInk : Color.spiceMuted))
                Text(time)
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(isCurrent ? Color.spiceTransit : Color.spiceMuted)
            }
            Spacer()
        }
    }
}
