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
    @State private var selectedDateRange: DateRange? = nil

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

                        // MARK: - Amber Date Notice Banner
                        if let range = selectedDateRange, range.isActive {
                            HStack(alignment: .center, spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(Color(hex: "#9C6212"))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Showing \(range.displayString.lowercased())")
                                        .font(.appFont(size: 13, weight: .heavy))
                                        .foregroundColor(Color(hex: "#8C580E"))

                                    Text("Your dashboard total covers every order, so it will be higher.")
                                        .font(.appFont(size: 11.5, weight: .medium))
                                        .foregroundColor(Color(hex: "#9C6212"))
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer()

                                Button(action: {
                                    selectedDateRange = nil
                                    loadOrders()
                                }) {
                                    Text("All time")
                                        .font(.appFont(size: 12.5, weight: .bold))
                                        .foregroundColor(Color(hex: "#8C580E"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: "#E8C89A"), lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(14)
                            .background(Color(hex: "#FEF4E6"))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color(hex: "#FAD8A8"), lineWidth: 1)
                            )
                        }

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
                            SpiceDateRangeFilterChip(selectedRange: $selectedDateRange, placeholder: "Any Date")

                            Spacer()

                            if selectedDateRange != nil || selectedStatusFilter != "All Orders" || !searchText.isEmpty {
                                Button(action: {
                                    selectedDateRange = nil
                                    selectedStatusFilter = "All Orders"
                                    searchText = ""
                                    loadOrders()
                                }) {
                                    Text("Clear all")
                                        .font(.appFont(size: 12.5, weight: .bold))
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
        NavigationLink(destination: OrderDetailScreen(orderId: order.id, orderNumber: order.orderNumberFormatted)) {
            VStack(alignment: .leading, spacing: 8) {
                // Top Row: Order ID + Status Badge
                HStack {
                    Text(order.orderNumberFormatted)
                        .font(.appFont(size: 14.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    Spacer()

                    statusBadge(status: order.statusLabel)
                }

                // Bottom Row: Date · Amount
                HStack(spacing: 6) {
                    Text(formatDate(order.orderDate ?? order.createdAt))
                        .font(.appFont(size: 12.5, weight: .regular))
                        .foregroundColor(Color.spiceMuted)

                    Text("·")
                        .font(.appFont(size: 12.5, weight: .bold))
                        .foregroundColor(Color.spiceMuted)

                    Text(formatOrderPrice(order))
                        .font(.appFont(size: 13, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
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
                return (Color(hex: "#FDF0DC"), Color(hex: "#A85B08"))
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
            .font(.appFont(size: 10.5, weight: .heavy))
            .foregroundColor(badgeColor.text)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(badgeColor.bg)
            .cornerRadius(6)
    }

    // MARK: - Format Price Helper
    private func formatOrderPrice(_ order: Order) -> String {
        let raw = (order.total?.isEmpty == false ? order.total : order.subtotal) ?? "0"
        let cleanRaw = raw.replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        if let doubleVal = Double(cleanRaw) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "en_IN")
            formatter.currencySymbol = "₹"
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: doubleVal)) ?? "₹\(cleanRaw)"
        }
        return "₹\(cleanRaw)"
    }

    // MARK: - Date Formatter Helper
    private func formatDate(_ raw: String?) -> String {
        guard let raw = raw, !raw.isEmpty else { return "" }
        let cleanRaw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatters = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd",
            "dd-MM-yyyy",
            "dd/MM/yyyy"
        ]

        for format in formatters {
            let df = DateFormatter()
            df.dateFormat = format
            df.locale = Locale(identifier: "en_US_POSIX")
            if let date = df.date(from: cleanRaw) {
                let out = DateFormatter()
                out.dateFormat = "d MMM yyyy"
                out.locale = Locale(identifier: "en_US_POSIX")
                return out.string(from: date)
            }
        }

        if cleanRaw.count >= 10 {
            let prefix = String(cleanRaw.prefix(10))
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            if let date = df.date(from: prefix) {
                let out = DateFormatter()
                out.dateFormat = "d MMM yyyy"
                out.locale = Locale(identifier: "en_US_POSIX")
                return out.string(from: date)
            }
        }

        return cleanRaw
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
