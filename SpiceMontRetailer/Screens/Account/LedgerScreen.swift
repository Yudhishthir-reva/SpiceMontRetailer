//
//  LedgerScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

enum LedgerViewTab {
    case orders
    case paymentHistory
}

struct LedgerScreen: View {
    @StateObject private var viewModel = LedgerViewModel()
    @State private var selectedTab: LedgerViewTab = .orders
    @State private var searchText: String = ""
    @State private var selectedType: String = "All"
    @State private var selectedPaymentMode: String = "All"
    @State private var expandedOrderIds: Set<Int> = []

    private let typeFilters = ["All", "Paid", "Partial", "Pending"]
    private let paymentModeFilters = ["All", "Cash", "UPI", "Cheque"]

    var filteredOrders: [RetailerLedgerOrderItem] {
        var list = viewModel.orders
        if selectedType != "All" {
            list = list.filter { $0.paymentStatusText?.localizedCaseInsensitiveContains(selectedType) == true }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            list = list.filter {
                ($0.orderNo?.localizedCaseInsensitiveContains(searchText) == true) ||
                ($0.paymentHistory?.contains { $0.remark?.localizedCaseInsensitiveContains(searchText) == true } == true)
            }
        }
        return list
    }

    var filteredPayments: [RetailerPaymentTransactionItem] {
        var list = viewModel.paymentTransactions
        if selectedPaymentMode != "All" {
            list = list.filter { $0.paymentMode?.localizedCaseInsensitiveContains(selectedPaymentMode) == true }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            list = list.filter {
                ($0.orderNo?.localizedCaseInsensitiveContains(searchText) == true) ||
                ($0.paymentMode?.localizedCaseInsensitiveContains(searchText) == true)
            }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            SpiceTopBar(title: "Outstanding Ledger", showBack: false)

            // Segmented Header
            HStack(spacing: 24) {
                Button(action: { selectedTab = .orders }) {
                    VStack(spacing: 6) {
                        Text("Orders Statement")
                            .font(.system(size: 13, weight: selectedTab == .orders ? .heavy : .bold))
                            .foregroundColor(selectedTab == .orders ? Color.spicePrimary : Color.spiceMuted)
                        Rectangle()
                            .fill(selectedTab == .orders ? Color.spicePrimary : Color.clear)
                            .frame(height: 2.5)
                    }
                }

                Button(action: { selectedTab = .paymentHistory }) {
                    VStack(spacing: 6) {
                        Text("Payment History")
                            .font(.system(size: 13, weight: selectedTab == .paymentHistory ? .heavy : .bold))
                            .foregroundColor(selectedTab == .paymentHistory ? Color.spicePrimary : Color.spiceMuted)
                        Rectangle()
                            .fill(selectedTab == .paymentHistory ? Color.spicePrimary : Color.clear)
                            .frame(height: 2.5)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            if viewModel.isLoading && viewModel.orders.isEmpty && viewModel.paymentTransactions.isEmpty {
                loadingSkeletonView
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        if selectedTab == .orders {
                            ordersSectionView
                        } else {
                            paymentHistorySectionView
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    viewModel.loadAll()
                }
                .background(Color.spiceBackground)
            }
        }
        .onAppear {
            viewModel.loadAll()
        }
        .toast(isPresenting: $viewModel.isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Orders Section (api/retailer/ledger)
    private var ordersSectionView: some View {
        VStack(spacing: 12) {
            // Summary Dark Card
            summaryCard

            // Payment Mode Breakdown Card
            if let mode = viewModel.summary?.paymentModeWise {
                paymentModeCard(mode)
            }

            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.spiceMuted)
                    .font(.system(size: 13, weight: .semibold))
                TextField("Search by order # or remark", text: $searchText)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(typeFilters, id: \.self) { filter in
                        Button(action: { selectedType = filter }) {
                            Text(filter)
                                .font(.system(size: 11.5, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedType == filter ? Color.spicePrimary : Color.white)
                                .foregroundColor(selectedType == filter ? .white : Color.spiceInk)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedType == filter ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            }

            // Orders Statement List
            if filteredOrders.isEmpty {
                SpiceEmptyStateView(
                    title: "No Ledger Entries",
                    message: "No orders or payment records match your selected filter.",
                    buttonTitle: "Refresh"
                ) {
                    viewModel.loadAll()
                }
                .padding(.top, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredOrders) { order in
                        orderLedgerCard(order)
                    }
                }
            }
        }
    }

    // MARK: - Payment History Section (api/retailer/ledger/payment-history)
    private var paymentHistorySectionView: some View {
        VStack(spacing: 12) {
            // Payment History Total Paid Card
            SpiceCard(backgroundColor: Color.spiceInk, borderColor: Color.spiceInk, padding: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TOTAL PAID AMOUNT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.spiceMuted.opacity(0.85))
                        .tracking(0.8)

                    Text("₹\(viewModel.paymentHistorySummary?.totalPaid ?? "3000.00")")
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(hex: "#7ED4A2"))

                    if let modeMap = viewModel.paymentHistorySummary?.paymentModeWise, !modeMap.isEmpty {
                        Divider().background(Color.white.opacity(0.15)).padding(.vertical, 2)
                        HStack(spacing: 16) {
                            ForEach(modeMap.sorted(by: { $0.key < $1.key }), id: \.key) { mode, amt in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.uppercased())
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color.spiceMuted.opacity(0.85))
                                    Text("₹\(amt)")
                                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
            }

            // Search Input
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.spiceMuted)
                    .font(.system(size: 13, weight: .semibold))
                TextField("Search by order # or payment mode", text: $searchText)
                    .font(.system(size: 12.5, weight: .medium))
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

            // Payment Mode Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(paymentModeFilters, id: \.self) { mode in
                        Button(action: { selectedPaymentMode = mode }) {
                            Text(mode)
                                .font(.system(size: 11.5, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedPaymentMode == mode ? Color.spicePrimary : Color.white)
                                .foregroundColor(selectedPaymentMode == mode ? .white : Color.spiceInk)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedPaymentMode == mode ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            }

            // Payment Transactions List
            if filteredPayments.isEmpty {
                SpiceEmptyStateView(
                    title: "No Payment Records",
                    message: "No payment transactions found matching your criteria.",
                    buttonTitle: "Refresh"
                ) {
                    viewModel.loadAll()
                }
                .padding(.top, 12)
            } else {
                VStack(spacing: 10) {
                    ForEach(filteredPayments) { txn in
                        paymentTransactionCard(txn)
                    }
                }
            }
        }
    }

    // MARK: - Summary Dark Card
    private var summaryCard: some View {
        SpiceCard(backgroundColor: Color.spiceInk, borderColor: Color.spiceInk, padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("TOTAL OUTSTANDING")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.spiceMuted.opacity(0.85))
                    .tracking(0.8)

                Text("₹\(viewModel.summary?.totalPending ?? "0.00")")
                    .font(.system(size: 28, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#FF6B6B"))

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TOTAL BILLED")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color.spiceMuted.opacity(0.85))
                        Text("₹\(viewModel.summary?.totalBilled ?? "0.00")")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("TOTAL PAID")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(Color.spiceMuted.opacity(0.85))
                        Text("₹\(viewModel.summary?.totalPaid ?? "0.00")")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color(hex: "#7ED4A2"))
                    }
                }
            }
        }
    }

    // MARK: - Payment Mode Breakdown
    private func paymentModeCard(_ modeMap: [String: String]) -> some View {
        SpiceCard(backgroundColor: Color.spiceAmberLight.opacity(0.25), borderColor: Color.spiceAmber.opacity(0.4), padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Mode Breakdown")
                    .font(.system(size: 11.5, weight: .heavy))
                    .foregroundColor(Color.spiceAmber)

                HStack(spacing: 16) {
                    ForEach(modeMap.sorted(by: { $0.key < $1.key }), id: \.key) { mode, amt in
                        HStack(spacing: 6) {
                            Image(systemName: mode.lowercased() == "cash" ? "banknote.fill" : (mode.lowercased() == "upi" ? "qrcode" : "creditcard.fill"))
                                .font(.system(size: 11))
                                .foregroundColor(mode.lowercased() == "cash" ? Color.spicePrimary : (mode.lowercased() == "upi" ? Color.spiceTransit : Color.spiceAmber))
                            Text("\(mode):")
                                .font(.system(size: 11.5, weight: .semibold))
                                .foregroundColor(Color.spiceInk)
                            Text("₹\(amt)")
                                .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color.spiceInk)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Order Ledger Card
    private func orderLedgerCard(_ order: RetailerLedgerOrderItem) -> some View {
        let isExpanded = expandedOrderIds.contains(order.id)
        let history = order.paymentHistory ?? []

        return SpiceCard(padding: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(order.orderNo ?? "#\(order.id)")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)
                        Text(order.orderDate ?? "")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        SpiceStatusBadge(status: order.paymentStatusText ?? "PENDING")
                        if let statusText = order.orderStatusText {
                            Text(statusText)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Billed").font(.system(size: 10, weight: .medium)).foregroundColor(Color.spiceMuted)
                        Text(String(format: "₹%.2f", order.billedAmount ?? 0))
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 2) {
                        Text("Paid").font(.system(size: 10, weight: .medium)).foregroundColor(Color.spiceMuted)
                        Text(String(format: "₹%.2f", order.paidAmount ?? 0))
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spicePrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Pending").font(.system(size: 10, weight: .medium)).foregroundColor(Color.spiceMuted)
                        Text(String(format: "₹%.2f", order.pendingAmount ?? 0))
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor((order.pendingAmount ?? 0) > 0 ? Color.spiceDue : Color.spicePrimary)
                    }
                }

                // Payment History Accordion
                if !history.isEmpty {
                    Divider().padding(.vertical, 2)

                    Button(action: {
                        if isExpanded {
                            expandedOrderIds.remove(order.id)
                        } else {
                            expandedOrderIds.insert(order.id)
                        }
                    }) {
                        HStack {
                            Text("Payment History (\(history.count))")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(Color.spicePrimary)
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.spicePrimary)
                        }
                    }

                    if isExpanded {
                        VStack(spacing: 6) {
                            ForEach(history) { rec in
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(rec.paymentMode?.uppercased() ?? "CASH")
                                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 1.5)
                                                .background(rec.paymentMode?.lowercased() == "online" ? Color.spiceTransitLight : Color.spicePrimaryLight)
                                                .foregroundColor(rec.paymentMode?.lowercased() == "online" ? Color.spiceTransit : Color.spicePrimary)
                                                .cornerRadius(4)

                                            Text(rec.date ?? "")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(Color.spiceMuted)
                                        }

                                        if let remark = rec.remark, !remark.isEmpty {
                                            Text("Remark: \(remark)")
                                                .font(.system(size: 10, weight: .medium))
                                                .foregroundColor(Color.spiceMuted)
                                        }
                                    }

                                    Spacer()

                                    Text(String(format: "₹%.2f", rec.amount ?? 0))
                                        .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                                        .foregroundColor(Color.spicePrimary)
                                }
                                .padding(8)
                                .background(Color.spiceBackground)
                                .cornerRadius(6)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
            }
        }
    }

    // MARK: - Payment Transaction Card
    private func paymentTransactionCard(_ txn: RetailerPaymentTransactionItem) -> some View {
        SpiceCard(padding: 12) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(txn.paymentMode?.lowercased() == "upi" ? Color.spiceTransitLight : Color.spicePrimaryLight)
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: txn.paymentMode?.lowercased() == "upi" ? "qrcode" : (txn.paymentMode?.lowercased() == "cheque" ? "doc.text.fill" : "banknote.fill"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(txn.paymentMode?.lowercased() == "upi" ? Color.spiceTransit : Color.spicePrimary)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(txn.orderNo ?? "#\(txn.orderId ?? txn.id ?? 0)")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)

                        Spacer()

                        Text(String(format: "₹%.2f", txn.amount ?? 0))
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spicePrimary)
                    }

                    HStack(spacing: 8) {
                        Text(txn.paymentMode?.uppercased() ?? "CASH")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.spiceLightGray)
                            .foregroundColor(Color.spiceInk)
                            .cornerRadius(4)

                        Text("Date: \(txn.date ?? "")")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    if let orderDate = txn.orderDate, !orderDate.isEmpty {
                        Text("Order Date: \(orderDate)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }
                }
            }
        }
    }

    // MARK: - Loading Skeleton
    private var loadingSkeletonView: some View {
        ScrollView {
            VStack(spacing: 12) {
                SpiceSkeletonBox(height: 120, cornerRadius: 16)
                SpiceSkeletonBox(height: 50, cornerRadius: 12)
                SpiceSkeletonBox(height: 40, cornerRadius: 10)
                ForEach(1...4, id: \.self) { _ in
                    SpiceSkeletonBox(height: 90, cornerRadius: 16)
                }
            }
            .padding(16)
        }
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
                totalBilled: "0.00",
                totalPaid: "0.00",
                totalPending: "0.00",
                paymentModeWise: ["Cash": "0.00", "Cheque": "0.00", "UPI": "0.00"]
            )
        }
    }

    private func loadMockPaymentHistoryFallback() {
        if paymentTransactions.isEmpty {
            paymentHistorySummary = RetailerPaymentHistorySummary(
                totalPaid: "3000.00",
                paymentModeWise: ["Cash": "1500.00", "Cheque": "500.00", "UPI": "1000.00"]
            )
        }
    }
}

