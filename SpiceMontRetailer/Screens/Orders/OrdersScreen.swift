//
//  OrdersScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

enum OrdersTab {
    case running
    case history
}

struct OrdersScreen: View {
    @State private var selectedTab: OrdersTab = .running
    @State private var runningFilter: String = "All"
    @State private var historyFilter: String = "All"
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss

    @State private var allOrders: [Order] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let runningChips = ["All", "Confirmed", "Processing", "Packed", "Dispatched", "Out for Delivery"]
    private let historyChips = ["All", "Delivered", "Cancelled"]

    private let orderService = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var runningOrders: [Order] {
        let running = allOrders.filter { order in
            let status = (order.status ?? "").lowercased()
            return status != "delivered" && status != "cancelled"
        }
        if runningFilter == "All" {
            return running
        }
        return running.filter { ($0.statusLabel).localizedCaseInsensitiveContains(runningFilter) }
    }

    var historyOrders: [Order] {
        var history = allOrders.filter { order in
            let status = (order.status ?? "").lowercased()
            return status == "delivered" || status == "cancelled"
        }
        if historyFilter != "All" {
            history = history.filter { ($0.statusLabel).localizedCaseInsensitiveContains(historyFilter) }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            history = history.filter {
                ($0.orderNumber?.localizedCaseInsensitiveContains(searchText) == true) ||
                ("\($0.id ?? 0)".localizedCaseInsensitiveContains(searchText))
            }
        }
        return history
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            SpiceTopBar(title: "My Orders", showBack: false)

            // Segmented Header
            HStack(spacing: 24) {
                Button(action: { selectedTab = .running }) {
                    VStack(spacing: 6) {
                        Text("Running Orders (\(runningOrders.count))")
                            .font(.system(size: 13, weight: selectedTab == .running ? .heavy : .bold))
                            .foregroundColor(selectedTab == .running ? Color.spicePrimary : Color.spiceMuted)
                        Rectangle()
                            .fill(selectedTab == .running ? Color.spicePrimary : Color.clear)
                            .frame(height: 2.5)
                    }
                }

                Button(action: { selectedTab = .history }) {
                    VStack(spacing: 6) {
                        Text("Order History (\(historyOrders.count))")
                            .font(.system(size: 13, weight: selectedTab == .history ? .heavy : .bold))
                            .foregroundColor(selectedTab == .history ? Color.spicePrimary : Color.spiceMuted)
                        Rectangle()
                            .fill(selectedTab == .history ? Color.spicePrimary : Color.clear)
                            .frame(height: 2.5)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            if isLoading && allOrders.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(1...4, id: \.self) { _ in
                            SpiceSkeletonBox(height: 140, cornerRadius: 16)
                        }
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        if selectedTab == .running {
                            runningSection
                        } else {
                            historySection
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    loadOrders()
                }
                .background(Color.spiceBackground)
            }
        }
        .onAppear {
            loadOrders()
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Running Section
    private var runningSection: some View {
        VStack(spacing: 12) {
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(runningChips, id: \.self) { chip in
                        Button(action: { runningFilter = chip }) {
                            Text(chip)
                                .font(.system(size: 11.5, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(runningFilter == chip ? Color.spicePrimary : Color.white)
                                .foregroundColor(runningFilter == chip ? .white : Color.spiceInk)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(runningFilter == chip ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1))
                        }
                    }
                }
            }

            if runningOrders.isEmpty {
                SpiceEmptyStateView(
                    title: "No Running Orders",
                    message: "You do not have any active running orders right now.",
                    buttonTitle: "Refresh"
                ) {
                    loadOrders()
                }
                .padding(.top, 20)
            } else {
                ForEach(runningOrders) { order in
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(order.orderNumberFormatted)
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.spiceInk)
                                Spacer()
                                SpiceStatusBadge(status: order.statusLabel.uppercased())
                            }

                            Text("\(order.createdAt ?? "") · \(order.itemsCount ?? order.items?.count ?? 0) items · \(order.total?.priceLabel ?? "₹0")")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)

                            // 5-Stage Bar
                            let stageIndex = progressStepIndex(for: order.status)
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { step in
                                    Rectangle()
                                        .fill(step <= stageIndex ? Color.spicePrimary : Color.spiceLightGray)
                                        .frame(height: 3)
                                        .cornerRadius(1.5)
                                }
                            }

                            HStack {
                                Text("Confirmed").frame(maxWidth: .infinity, alignment: .leading)
                                Text("Packed").frame(maxWidth: .infinity, alignment: .center)
                                Text("Delivered").frame(maxWidth: .infinity, alignment: .trailing)
                            }
                            .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)

                            HStack(spacing: 8) {
                                NavigationLink(destination: DeliveryTrackingScreen(orderNumber: order.orderNumberFormatted)) {
                                    Text("Track Order")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(Color.spicePrimary)
                                        .cornerRadius(8)
                                }

                                NavigationLink(destination: OrderDetailScreen(orderId: "\(order.id ?? 0)")) {
                                    Text("View Details")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - History Section
    private var historySection: some View {
        VStack(spacing: 12) {
            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.spiceMuted)
                    .font(.system(size: 13, weight: .semibold))
                TextField("Search order number", text: $searchText)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(historyChips, id: \.self) { chip in
                        Button(action: { historyFilter = chip }) {
                            Text(chip)
                                .font(.system(size: 11.5, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(historyFilter == chip ? Color.spicePrimary : Color.white)
                                .foregroundColor(historyFilter == chip ? .white : Color.spiceInk)
                                .cornerRadius(20)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(historyFilter == chip ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1))
                        }
                    }
                }
            }

            if historyOrders.isEmpty {
                SpiceEmptyStateView(
                    title: "No Order History",
                    message: "No delivered or past orders found.",
                    buttonTitle: "Refresh"
                ) {
                    loadOrders()
                }
                .padding(.top, 20)
            } else {
                ForEach(historyOrders) { order in
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(order.orderNumberFormatted)
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.spiceInk)
                                Spacer()
                                SpiceStatusBadge(status: order.statusLabel.uppercased())
                            }

                            Text("\(order.createdAt ?? "") · \(order.itemsCount ?? order.items?.count ?? 0) items · \(order.total?.priceLabel ?? "₹0")")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)

                            HStack(spacing: 8) {
                                if (order.status ?? "").lowercased() == "delivered" {
                                    NavigationLink(destination: CartScreen()) {
                                        Text("Repeat Order")
                                            .font(.system(size: 11.5, weight: .heavy))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 34)
                                            .background(Color.spicePrimary)
                                            .cornerRadius(8)
                                    }

                                    NavigationLink(destination: GSTInvoiceScreen(invoiceNumber: "INV-\(order.id ?? 1000)", orderNumber: order.orderNumberFormatted)) {
                                        Text("Invoice")
                                            .font(.system(size: 11.5, weight: .bold))
                                            .foregroundColor(Color.spiceInk)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 34)
                                            .background(Color.white)
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))
                                            .cornerRadius(8)
                                    }
                                }

                                NavigationLink(destination: OrderDetailScreen(orderId: "\(order.id ?? 0)")) {
                                    Text("Details")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(Color.spiceInk)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(Color.white)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

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

    private func progressStepIndex(for status: String?) -> Int {
        switch (status ?? "").lowercased() {
        case "pending", "confirmed": return 1
        case "processing": return 2
        case "packed", "shipped": return 3
        case "out_for_delivery", "out for delivery": return 4
        case "delivered": return 5
        default: return 1
        }
    }
}
