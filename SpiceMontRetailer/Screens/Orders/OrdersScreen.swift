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
    @State private var selectedDateRange: DateRange? = DateRange.today

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

        // 2. Date Range Filter
        if let range = selectedDateRange, range.isActive {
            list = list.filter { order in
                if let oDate = order.orderDate, range.contains(dateString: oDate) { return true }
                if let cDate = order.createdAt, range.contains(dateString: cDate) { return true }
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
        ZStack {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        // MARK: - Search Bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.spiceMuted)
                                .font(.appFont(size: 14, weight: .semibold))

                            TextField("Search loaded orders by number", text: $searchText)
                                .font(.appFont(size: 13, weight: .medium))
                                .foregroundColor(Color.black)
                                .tint(Color.spicePrimary)
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
                                            .font(.appFont(size: 12.5, weight: .bold))
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
                            .padding(.vertical, 1)
                        }

                        // MARK: - Date Range Filter Chip & Clear All (Calendar Sheet)
                        HStack {
                            SpiceDateRangeFilterChip(selectedRange: $selectedDateRange)

                            Spacer()

                            if selectedDateRange != nil || selectedStatusFilter != "All Orders" || !searchText.isEmpty {
                                Button(action: {
                                    selectedDateRange = nil
                                    selectedStatusFilter = "All Orders"
                                    searchText = ""
                                    loadOrders()
                                }) {
                                    Text("Clear all")
                                        .font(.appFont(size: 12, weight: .bold))
                                        .foregroundColor(Color.spicePrimary)
                                }
                            }
                        }

                        // MARK: - Orders List or Skeletons
                        if isLoading && allOrders.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SpiceSkeletonBox(height: 140, cornerRadius: 16)
                                }
                            }
                        } else if displayedOrders.isEmpty {
                            if allOrders.isEmpty {
                                SpiceEmptyStateView(
                                    title: "No Orders Placed Yet",
                                    message: "You haven't placed any orders with SpiceMonk yet. Explore brands to create your first order.",
                                    buttonTitle: "Explore Brands"
                                ) {
                                    loadOrders()
                                }
                                .padding(.top, 30)
                            } else {
                                SpiceEmptyStateView(
                                    title: "No Orders Found",
                                    message: "No orders match your filter criteria.",
                                    buttonTitle: "Refresh"
                                ) {
                                    loadOrders()
                                }
                                .padding(.top, 30)
                            }
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
                    .padding(.top, 10)
                }
                .refreshable {
                    loadOrders()
                }
            }
        }
        .navigationTitle("My Orders")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    loadOrders()
                }) {
                    Text("Refresh")
                        .font(.appFont(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }
        }
        .onAppear {
            loadOrders()
        }
        .onChange(of: selectedDateRange) { _, _ in
            loadOrders()
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Order Card Component
    @ViewBuilder
    private func orderCardView(order: Order) -> some View {
        let isAssigned = (order.status ?? "").lowercased() == "assigned"

        NavigationLink(destination: OrderDetailScreen(orderId: order.id, orderNumber: order.orderNumberFormatted)) {
            VStack(alignment: .leading, spacing: 10) {
                // Top Row: Order ID + Status
                HStack {
                    Text(order.orderNumberFormatted)
                        .font(.appFont(size: 14.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)

                    Spacer()

                    statusBadge(status: order.statusLabel)
                }

                // Middle Row: Date & Items Count
                HStack {
                    Text(formatDate(order.orderDate ?? order.createdAt))
                        .font(.appFont(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)

                    Spacer()

                    let count = order.items?.count ?? order.itemsCount ?? 0
                    Text("\(count) items")
                        .font(.appFont(size: 12, weight: .semibold))
                        .foregroundColor(Color.spiceInk)
                }

                Divider().background(Color.spiceDivider).padding(.vertical, 2)

                // Bottom Row: Total Amount & Track button / Chevron
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Bill Amount")
                            .font(.appFont(size: 10.5, weight: .medium))
                            .foregroundColor(Color.spiceMuted)

                        Text(order.totalPriceFormatted)
                            .font(.appFont(size: 14.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)
                    }

                    Spacer()

                    if isAssigned {
                        NavigationLink(destination: DeliveryTrackingScreen(orderId: order.id, orderNumber: order.orderNumberFormatted)) {
                            Text("Track")
                                .font(.appFont(size: 12, weight: .heavy))
                                .foregroundColor(Color.spicePrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.spicePrimaryLight)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 4) {
                            Text("Details")
                                .font(.appFont(size: 12, weight: .bold))
                                .foregroundColor(Color.spicePrimary)
                            Image(systemName: "chevron.right")
                                .font(.appFont(size: 10, weight: .bold))
                                .foregroundColor(Color.spicePrimary)
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.spiceCardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Badge View
    @ViewBuilder
    private func statusBadge(status: String) -> some View {
        let cleanStatus = status.trimmingCharacters(in: .whitespacesAndNewlines)

        let badgeColor: (bg: Color, text: Color) = {
            let lower = cleanStatus.lowercased()
            if lower.contains("pending") {
                return (Color(hex: "#FEF4E6"), Color(hex: "#B87314"))
            } else if lower.contains("assign") {
                return (Color(hex: "#E8F0FE"), Color(hex: "#1A73E8"))
            } else if lower.contains("deliver") {
                return (Color(hex: "#EBF7EE"), Color(hex: "#167444"))
            } else if lower.contains("cancel") {
                return (Color(hex: "#FDECEB"), Color(hex: "#C8322B"))
            } else {
                return (Color.spiceLightGray, Color.spiceInk)
            }
        }()

        Text(cleanStatus.uppercased())
            .font(.appFont(size: 10, weight: .heavy, design: .monospaced))
            .foregroundColor(badgeColor.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(badgeColor.bg)
            .cornerRadius(5)
    }

    // MARK: - Date Formatter Helper
    private func formatDate(_ raw: String?) -> String {
        guard let raw = raw, !raw.isEmpty else { return "" }
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

        var params: [String: Any] = [:]
        if let range = selectedDateRange, range.isActive {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            params["start_date"] = formatter.string(from: range.startDate)
            params["end_date"] = formatter.string(from: range.endDate)
        }

        orderService.fetchOrders(params: params, headers: headers)
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

#Preview {
    OrdersScreen()
}
