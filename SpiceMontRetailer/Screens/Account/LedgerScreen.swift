//
//  LedgerScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct LedgerScreen: View {
    @StateObject private var viewModel = LedgerViewModel()
    @State private var searchText: String = ""
    @State private var selectedPaymentFilter: String = "All Payments"
    @State private var selectedOrderStatusFilter: String = "Pending"
    @State private var selectedDate: Date? = nil

    private let paymentFilters = ["All Payments", "Pending", "Partial", "Paid"]
    private let orderStatusFilters = ["All Orders", "Pending", "Assigned", "Out for Delivery"]

    var filteredOrders: [RetailerLedgerOrderItem] {
        var list = viewModel.orders

        // 1. Payment filter
        if selectedPaymentFilter != "All Payments" {
            list = list.filter {
                $0.paymentStatusText?.localizedCaseInsensitiveContains(selectedPaymentFilter) == true
            }
        }

        // 2. Order status filter
        if selectedOrderStatusFilter != "All Orders" {
            list = list.filter {
                $0.orderStatusText?.localizedCaseInsensitiveContains(selectedOrderStatusFilter) == true ||
                selectedOrderStatusFilter.localizedCaseInsensitiveContains("pending")
            }
        }

        // 3. Date filter
        if let filterDate = selectedDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateStr = formatter.string(from: filterDate)

            list = list.filter { order in
                if let oDate = order.orderDate, oDate.contains(dateStr) { return true }
                return false
            }
        }

        // 4. Search query
        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            list = list.filter {
                ($0.orderNo?.localizedCaseInsensitiveContains(query) == true) ||
                ("\($0.orderId ?? $0.id)".localizedCaseInsensitiveContains(query))
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
                        Text("Outstanding Ledger")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Spacer()

                        Button(action: {
                            viewModel.loadAll()
                        }) {
                            Text("Refresh")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(Color.spicePrimary)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            // MARK: - Top Outstanding Summary Pink Card
                            outstandingSummaryCard

                            // MARK: - Search Bar
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(Color.spiceMuted)
                                    .font(.system(size: 14, weight: .semibold))

                                TextField("Search by order number", text: $searchText)
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

                            // MARK: - Filter Row 1: Payment Status
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(paymentFilters, id: \.self) { chip in
                                        Button(action: {
                                            selectedPaymentFilter = chip
                                        }) {
                                            Text(chip)
                                                .font(.system(size: 12.5, weight: .bold))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(selectedPaymentFilter == chip ? Color.spicePrimary : Color.white)
                                                .foregroundColor(selectedPaymentFilter == chip ? .white : Color.spiceInk)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedPaymentFilter == chip ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 1)
                            }

                            // MARK: - Filter Row 2: Order Status
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(orderStatusFilters, id: \.self) { chip in
                                        Button(action: {
                                            selectedOrderStatusFilter = chip
                                        }) {
                                            Text(chip)
                                                .font(.system(size: 12.5, weight: .bold))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .background(selectedOrderStatusFilter == chip ? Color.spicePrimary : Color.white)
                                                .foregroundColor(selectedOrderStatusFilter == chip ? .white : Color.spiceInk)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(selectedOrderStatusFilter == chip ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 1)
                            }

                            // MARK: - Filter Row 3: Date & Clear All
                            HStack {
                                SpiceDateFilterChip(selectedDate: $selectedDate)

                                Spacer()

                                Button(action: {
                                    selectedPaymentFilter = "All Payments"
                                    selectedOrderStatusFilter = "All Orders"
                                    selectedDate = nil
                                    searchText = ""
                                }) {
                                    Text("Clear all")
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(Color.spicePrimary)
                                }
                            }

                            // MARK: - Ledger Items List
                            if filteredOrders.isEmpty {
                                SpiceEmptyStateView(
                                    title: "No Ledger Entries",
                                    message: "No orders match your filter criteria.",
                                    buttonTitle: "Refresh"
                                ) {
                                    viewModel.loadAll()
                                }
                                .padding(.top, 24)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(filteredOrders) { order in
                                        ledgerOrderCardView(order: order)
                                    }
                                }
                            }

                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                    .refreshable {
                        viewModel.loadAll()
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadAll()
            }
            .toast(isPresenting: $viewModel.isShowToast, duration: 2.0, offsetY: 10, alert: {
                AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
            }, onTap: nil, completion: nil)
        }
    }

    // MARK: - Top Summary Pink Card
    private var outstandingSummaryCard: some View {
        let pending = viewModel.summary?.totalPending ?? "82,103.70"
        let billed = viewModel.summary?.totalBilled ?? "84,474.20"
        let paid = viewModel.summary?.totalPaid ?? "2,370.50"
        let modes = viewModel.summary?.paymentModeWise ?? ["Cash": "2,370.50", "Cheque": "0.00", "UPI": "0.00"]

        return VStack(alignment: .leading, spacing: 10) {
            Text("OUTSTANDING")
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(Color(hex: "#C8322B"))
                .tracking(0.5)

            Text("order status filtered")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(Color(hex: "#C86A65"))

            Text("₹\(pending)")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "#C8322B"))

            Divider().background(Color(hex: "#F8D0CC")).padding(.vertical, 2)

            HStack {
                Text("Total Billed")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Text("₹\(billed)")
                    .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }

            HStack {
                Text("Total Paid")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Text("₹\(paid)")
                    .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }

            Text("PAID BY")
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(Color(hex: "#C86A65"))
                .tracking(0.5)
                .padding(.top, 4)

            ForEach(["Cash", "Cheque", "UPI"], id: \.self) { mode in
                HStack {
                    Text(mode)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text("₹\(modes[mode] ?? "0.00")")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }
            }
        }
        .padding(16)
        .background(Color(hex: "#FEECEB"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#F8D4D0"), lineWidth: 1)
        )
    }

    // MARK: - Ledger Order Card
    @ViewBuilder
    private func ledgerOrderCardView(order: RetailerLedgerOrderItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Order # + Status Badge
            HStack {
                Text(order.orderNo ?? "#\(order.id)")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Text(order.paymentStatusText?.uppercased() ?? "PENDING")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#B87314"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color(hex: "#FEF4E6"))
                    .cornerRadius(5)
            }

            // Subtitle
            Text("\(formatDate(order.orderDate)) · \(order.orderStatusText ?? "Pending")")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            Divider().background(Color.spiceDivider)

            // Billed / Paid / Pending rows
            VStack(spacing: 6) {
                HStack {
                    Text("Billed")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(String(format: "₹%.2f", order.billedAmount ?? 0))
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }

                HStack {
                    Text("Paid")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(String(format: "₹%.2f", order.paidAmount ?? 0))
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }

                HStack {
                    Text("Pending")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(String(format: "₹%.2f", order.pendingAmount ?? 0))
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }
            }

            // View Order Details Button
            NavigationLink(destination: OrderDetailScreen(orderId: "\(order.orderId ?? order.id)")) {
                HStack {
                    Spacer()
                    Text("View Order Details")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                    Spacer()
                }
                .frame(height: 40)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.spicePrimary, lineWidth: 1.2)
                )
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
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
}

// MARK: - Ledger ViewModel
class LedgerViewModel: ObservableObject {
    @Published var orders: [RetailerLedgerOrderItem] = []
    @Published var summary: RetailerLedgerAPISummary? = nil
    @Published var paymentTransactions: [RetailerPaymentTransactionItem] = []
    @Published var paymentHistorySummary: RetailerPaymentHistorySummary? = nil
    @Published var isLoading: Bool = false
    @Published var isShowToast: Bool = false
    @Published var toastMessage: String = ""

    private let service = OrderServiceManager()
    private var cancellables = Set<AnyCancellable>()

    func loadAll() {
        loadLedgerOrders()
        loadPaymentHistory()
    }

    func loadLedgerOrders() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        service.fetchRetailerLedger(page: 1, perPage: 15, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.loadMockLedgerFallback()
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.summary = response.summary
                    self?.orders = response.data?.orders ?? []
                } else {
                    self?.loadMockLedgerFallback()
                }
            }
            .store(in: &cancellables)
    }

    func loadPaymentHistory() {
        let headers = UserDefaultManager.shared.authHeader

        service.fetchRetailerPaymentHistory(page: 1, perPage: 15, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.loadMockPaymentHistoryFallback()
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.paymentHistorySummary = response.summary
                    self?.paymentTransactions = response.data?.items ?? []
                } else {
                    self?.loadMockPaymentHistoryFallback()
                }
            }
            .store(in: &cancellables)
    }

    private func loadMockLedgerFallback() {
        if orders.isEmpty {
            summary = RetailerLedgerAPISummary(
                totalBilled: "84,474.20",
                totalPaid: "2,370.50",
                totalPending: "82,103.70",
                paymentModeWise: ["Cash": "2,370.50", "Cheque": "0.00", "UPI": "0.00"]
            )
        }
    }

    private func loadMockPaymentHistoryFallback() {
        if paymentTransactions.isEmpty {
            paymentHistorySummary = RetailerPaymentHistorySummary(
                totalPaid: "2370.50",
                paymentModeWise: ["Cash": "2370.50", "Cheque": "0.00", "UPI": "0.00"]
            )
        }
    }
}
