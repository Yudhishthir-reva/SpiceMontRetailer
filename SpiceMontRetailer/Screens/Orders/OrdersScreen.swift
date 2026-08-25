//
//  OrdersScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct OrdersScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedStatusFilter: String = "All Orders"
    @State private var selectedDate: Date? = nil

    @State private var allOrders: [Order] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let statusChips = [
        "All Orders",
        "Pending",
        "Assigned",
        "Out for Delivery",
        "Delivered",
        "Cancelled"
    ]

    private let orderService = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var displayedOrders: [Order] {
        var list = allOrders

        // 1. Status Filter
        if selectedStatusFilter != "All Orders" {
            list = list.filter {
                $0.statusLabel.localizedCaseInsensitiveContains(selectedStatusFilter) ||
                ($0.status ?? "").localizedCaseInsensitiveContains(selectedStatusFilter)
            }
        }

        // 2. Date Filter
        if let filterDate = selectedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: filterDate)

            list = list.filter { order in
                if let oDate = order.orderDate, oDate.contains(dateStr) { return true }
                if let cDate = order.createdAt, cDate.contains(dateStr) { return true }
                return false
            }
        }

        // 3. Search Text
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            list = list.filter {
                $0.orderNumberFormatted.localizedCaseInsensitiveContains(trimmed) ||
                ("\($0.id ?? 0)".localizedCaseInsensitiveContains(trimmed))
            }
        }

        return list
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.spiceBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Header
                    HStack {
                        Text("My Orders")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            // MARK: - Search Bar
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color.spiceMuted)
                                    .font(.system(size: 14, weight: .semibold))

                                TextField("Search loaded orders by number", text: $searchText)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 46)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.spiceCardBorder, lineWidth: 1)
                            )

                            // MARK: - Status Filter Chips
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(statusChips, id: \.self) { chip in
                                        Button(action: {
                                            selectedStatusFilter = chip
                                        }) {
                                            Text(chip)
                                                .font(.system(size: 12.5, weight: .bold))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(selectedStatusFilter == chip ? Color.spicePrimary : Color.white)
                                                .foregroundColor(selectedStatusFilter == chip ? .white : Color.spiceInk)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedStatusFilter == chip ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)
                            }

                            // MARK: - Date Filter Chip
                            HStack {
                                SpiceDateFilterChip(selectedDate: $selectedDate)
                                Spacer()
                            }

                            // MARK: - Order Cards List
                            if displayedOrders.isEmpty {
                                SpiceEmptyStateView(
                                    title: "No Orders Found",
                                    message: "No orders match your filter criteria.",
                                    buttonTitle: "Refresh"
                                ) {
                                    loadOrders()
                                }
                                .padding(.top, 30)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(displayedOrders) { order in
                                        orderCardView(order: order)
                                    }
                                }
                            }

                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                    .refreshable {
                        loadOrders()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadOrders()
            }
            .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
                AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
            }, onTap: nil, completion: nil)
        }
    }

    // MARK: - Order Card Component
    @ViewBuilder
    private func orderCardView(order: Order) -> some View {
        let isAssigned = (order.status ?? "").lowercased() == "assigned"
        let isOutForDelivery = (order.status ?? "").lowercased().contains("out")
        let isProcessing = (order.status ?? "").lowercased() == "processing"
        let showTrackButton = isAssigned || isOutForDelivery || isProcessing

        NavigationLink(destination: OrderDetailScreen(orderId: "\(order.id ?? 0)")) {
            VStack(alignment: .leading, spacing: 10) {
                // Top Row: Order Number + Status Badge
                HStack {
                    Text(order.orderNumberFormatted)
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)

                    Spacer()

                    statusBadgeView(status: order.statusLabel)
                }

                // Middle Row: Date & Amount
                HStack(spacing: 6) {
                    Text(formatDate(order.displayDateOnly))
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)

                    Text("·")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(Color.spiceMuted)

                    Text(order.total?.priceLabel ?? "₹0.00")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }

                // Optional Bottom Action: Track Order
                if showTrackButton {
                    NavigationLink(destination: DeliveryTrackingScreen(orderId: order.id, orderNumber: order.orderNumberFormatted)) {
                        HStack {
                            Spacer()
                            Text("Track Order")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(height: 42)
                        .background(Color.spicePrimary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Badge
    @ViewBuilder
    private func statusBadgeView(status: String) -> some View {
        let cleanStatus = status.uppercased()
        let badgeColor: (bg: Color, text: Color) = {
            switch cleanStatus {
            case "PENDING":
                return (Color(hex: "#FEF4E6"), Color(hex: "#B87314"))
            case "ASSIGNED":
                return (Color(hex: "#EBF3FE"), Color(hex: "#2563EB"))
            case "OUT FOR DELIVERY", "SHIPPED", "DISPATCHED":
                return (Color(hex: "#EDE9FE"), Color(hex: "#6D28D9"))
            case "DELIVERED":
                return (Color(hex: "#E8F8EE"), Color(hex: "#167444"))
            case "CANCELLED", "REJECTED":
                return (Color(hex: "#FEECEB"), Color(hex: "#DC2626"))
            default:
                return (Color(hex: "#FEF4E6"), Color(hex: "#B87314"))
            }
        }()

        Text(cleanStatus)
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundColor(badgeColor.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(badgeColor.bg)
            .cornerRadius(5)
    }

    // MARK: - Date Formatter Helper
    private func formatDate(_ raw: String?) -> String {
        guard let raw = raw, !raw.isEmpty else { return "24 Aug 2026" }
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        if let d = iso.date(from: String(raw.prefix(10))) {
            let out = DateFormatter()
            out.dateFormat = "d MMM yyyy"
            return out.string(from: d)
        }
        return raw
    }

    // MARK: - Load Orders
    private func loadOrders() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        orderService.fetchOrders(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                self.allOrders = response.orders ?? []
            }
            .store(in: &cancellables)
    }
}
