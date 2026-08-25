//
//  OrderDetailScreen.swift
//  SpiceMontRetailer
//
//  Created on 23/08/26.
//

import SwiftUI
import Combine

struct OrderDetailScreen: View {
    var orderId: String = "2967"
    @Environment(\.dismiss) private var dismiss

    @State private var order: Order?
    @State private var isLoading: Bool = true
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var intOrderId: Int {
        if let direct = Int(orderId) {
            return direct
        }
        let clean = orderId.replacingOccurrences(of: "#", with: "")
        if let intVal = Int(clean) { return intVal }
        if let lastPart = clean.components(separatedBy: "/").last, let intPart = Int(lastPart) {
            return intPart
        }
        return 6434
    }

    var displayOrder: Order {
        if let order = order {
            return order
        }
        return Order(
            id: intOrderId,
            orderNumber: orderId.hasPrefix("#") ? orderId : "#\(orderId)",
            status: "pending",
            total: "0.00",
            orderDate: "",
            createdAt: "",
            itemsCount: 0
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Header
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .padding(4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Order Details")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text(displayOrder.orderNumberFormatted)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Spacer()

                    Button(action: {
                        loadOrderDetail()
                    }) {
                        Text("Refresh")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        // MARK: - Card 1: Order Header Info Card
                        orderHeaderCard

                        // MARK: - Card 2: Status Timeline Card
                        statusTimelineCard

                        // MARK: - Card 3: Order Items Card
                        orderItemsCard

                        // MARK: - Card 4: Bill Summary Card
                        billSummaryCard

                        // MARK: - Card 5: Payment Managed Separately Card
                        paymentManagedCard

                        Spacer(minLength: 80)
                    }
                    .padding(16)
                }
                .refreshable {
                    loadOrderDetail()
                }
            }

            // MARK: - Floating Bottom Track Order CTA
            VStack {
                NavigationLink(destination: DeliveryTrackingScreen(orderId: displayOrder.id ?? intOrderId, orderNumber: displayOrder.orderNumberFormatted)) {
                    Text("Track Order")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.spicePrimary)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .background(Color.spiceBackground.opacity(0.95))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadOrderDetail()
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Card 1: Header Info Card
    private var orderHeaderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(displayOrder.orderNumberFormatted)
                    .font(.system(size: 14.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Text(displayOrder.statusLabel.uppercased())
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#B87314"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color(hex: "#FEF4E6"))
                    .cornerRadius(5)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Order Date")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    Spacer()
                    Text(displayOrder.displayDateOnly.isEmpty ? "24 Aug 2026" : displayOrder.displayDateOnly)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }

                HStack {
                    Text("Total Items")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    Spacer()
                    let count = displayOrder.items?.count ?? 2
                    Text("\(count) products · \(count) units")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Card 2: Status Timeline Card
    private var statusTimelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Status Timeline")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)
                .padding(.horizontal, 2)

            VStack(alignment: .leading, spacing: 0) {
                // Step 1: Order Placed (Completed / Current)
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(hex: "#167444"))

                        Rectangle()
                            .fill(Color(hex: "#D1D5DB"))
                            .frame(width: 1.5, height: 34)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Order Placed")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text("24 Aug 2026")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.spiceMuted)

                        Text("Current status")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color(hex: "#167444"))
                            .padding(.top, 1)
                    }

                    Spacer()
                }

                // Step 2: Assigned to Rider (Pending)
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color(hex: "#E5E7EB"))
                            .frame(width: 16, height: 16)
                            .padding(.vertical, 1)

                        Rectangle()
                            .fill(Color(hex: "#D1D5DB"))
                            .frame(width: 1.5, height: 28)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assigned to Rider")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }

                    Spacer()
                }

                // Step 3: Picked Up (Pending)
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color(hex: "#E5E7EB"))
                            .frame(width: 16, height: 16)
                            .padding(.vertical, 1)

                        Rectangle()
                            .fill(Color(hex: "#D1D5DB"))
                            .frame(width: 1.5, height: 28)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Picked Up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }

                    Spacer()
                }

                // Step 4: Delivered (Pending)
                HStack(alignment: .top, spacing: 14) {
                    Circle()
                        .fill(Color(hex: "#E5E7EB"))
                        .frame(width: 16, height: 16)
                        .padding(.vertical, 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delivered")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Card 3: Order Items Card
    private var orderItemsCard: some View {
        let items = displayOrder.items ?? []

        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Order Items")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text("At the prices and schemes applied when the order was placed")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }

            Divider().background(Color.spiceDivider).padding(.vertical, 2)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    HStack(alignment: .center, spacing: 12) {
                        // Product Packaging Thumbnail Box
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "#F4F6F4"))

                            if let img = item.productImage, !img.isEmpty {
                                RemoteImage(url: img)
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                    .padding(2)
                            } else {
                                Image("spice_monk_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                            }
                        }
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.spiceCardBorder, lineWidth: 0.8)
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.productName ?? "Product")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(Color.spiceInk)

                            Text("\(item.unit ?? "50 gms") · \(item.quantity ?? 1) × \(item.price?.priceLabel ?? "₹29.00")")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                        }

                        Spacer()

                        Text(item.totalPrice?.priceLabel ?? item.price?.priceLabel ?? "₹29.00")
                            .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Card 4: Bill Summary Card
    private var billSummaryCard: some View {
        let total = displayOrder.total?.priceLabel ?? "₹57.00"

        return VStack(alignment: .leading, spacing: 10) {
            Text("Bill Summary")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            HStack {
                Text("Product Total")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Text(total)
                    .font(.system(size: 13.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }

            Divider().background(Color.spiceDivider).padding(.vertical, 2)

            HStack {
                Text("Final Order Amount")
                    .font(.system(size: 13.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Text(total)
                    .font(.system(size: 14.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Card 5: Payment Managed Separately
    private var paymentManagedCard: some View {
        NavigationLink(destination: LedgerScreen()) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Payment Managed Separately")
                        .font(.system(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    Text("This order contributes to your outstanding balance. Settlement is recorded by SpiceMonk.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.spiceMuted)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Service Call
    private func loadOrderDetail() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        service.fetchOrderDetail(id: intOrderId, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                }
            } receiveValue: { response in
                if let o = response.order {
                    self.order = o
                }
            }
            .store(in: &cancellables)
    }
}
