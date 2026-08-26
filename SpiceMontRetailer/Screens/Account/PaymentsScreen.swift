//
//  PaymentsScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct PaymentsScreen: View {
    @StateObject private var viewModel = PaymentsViewModel()
    @State private var selectedModeFilter: String = "All Modes"
    @State private var selectedDateRange: DateRange? = DateRange.today

    private let modeFilters = ["All Modes", "Cash", "Cheque", "UPI"]

    var filteredTransactions: [RetailerPaymentTransactionItem] {
        var list = viewModel.transactions

        if selectedModeFilter != "All Modes" {
            list = list.filter {
                $0.paymentMode?.localizedCaseInsensitiveContains(selectedModeFilter) == true
            }
        }

        if let range = selectedDateRange, range.isActive {
            list = list.filter { txn in
                if let tDate = txn.date, range.contains(dateString: tDate) { return true }
                if let oDate = txn.orderDate, range.contains(dateString: oDate) { return true }
                return false
            }
        }

        return list
    }

    var filterSubtitleText: String {
        let modeText = selectedModeFilter
        let dateText = selectedDateRange?.displayString ?? "All Time"
        return "\(modeText), \(dateText)"
    }

    var body: some View {
        ZStack {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // MARK: - Top Total Paid Summary Mint Card
                        totalPaidSummaryCard

                        // MARK: - Payment Mode Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(modeFilters, id: \.self) { mode in
                                    Button(action: {
                                        selectedModeFilter = mode
                                    }) {
                                        Text(mode)
                                            .font(.system(size: 12.5, weight: .bold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(selectedModeFilter == mode ? Color.spicePrimary : Color.white)
                                            .foregroundColor(selectedModeFilter == mode ? .white : Color.spiceInk)
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(selectedModeFilter == mode ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 1)
                        }

                        // MARK: - Filter Row 2: Date Filter (Calendar Sheet)
                        HStack {
                            SpiceDateRangeFilterChip(selectedRange: $selectedDateRange)

                            Spacer()

                            if selectedDateRange != nil || selectedModeFilter != "All Modes" {
                                Button(action: {
                                    selectedDateRange = nil
                                    selectedModeFilter = "All Modes"
                                }) {
                                    Text("Clear all")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.spicePrimary)
                                }
                            }
                        }

                        // MARK: - Transactions List or Skeletons
                        if viewModel.isLoading && viewModel.transactions.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SpiceSkeletonBox(height: 180, cornerRadius: 16)
                                }
                            }
                        } else if filteredTransactions.isEmpty {
                            if viewModel.transactions.isEmpty {
                                SpiceEmptyStateView(
                                    title: "No Payment History",
                                    message: "No payment transactions have been recorded for your account yet.",
                                    buttonTitle: "Refresh"
                                ) {
                                    viewModel.loadPayments()
                                }
                                .padding(.top, 24)
                            } else {
                                SpiceEmptyStateView(
                                    title: "No Transactions Found",
                                    message: "No payments match your filter criteria.",
                                    buttonTitle: "Refresh"
                                ) {
                                    viewModel.loadPayments()
                                }
                                .padding(.top, 24)
                            }
                        } else {
                            VStack(spacing: 12) {
                                ForEach(filteredTransactions) { txn in
                                    paymentCardView(txn: txn)
                                }
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
                .refreshable {
                    viewModel.loadPayments()
                }
            }
        }
        .navigationTitle("Payments")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.loadPayments()
                }) {
                    Text("Refresh")
                        .font(.system(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }
        }
        .onAppear {
            viewModel.loadPayments()
        }
        .toast(isPresenting: $viewModel.isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Top Summary Mint Card
    private var totalPaidSummaryCard: some View {
        let totalPaid = viewModel.summary?.totalPaid ?? "0.00"
        let modes = viewModel.summary?.paymentModeWise ?? ["Cash": "0.00", "Cheque": "0.00", "UPI": "0.00"]

        return VStack(alignment: .leading, spacing: 10) {
            Text("TOTAL PAID")
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(Color(hex: "#167444"))
                .tracking(0.5)

            Text("All time")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(Color(hex: "#5B8A6E"))

            Text("₹\(totalPaid)")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "#167444"))

            Divider().background(Color(hex: "#C8E8D2")).padding(.vertical, 2)

            Text("PAID BY")
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(Color(hex: "#5B8A6E"))
                .tracking(0.5)
                .padding(.top, 2)

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
        .background(Color(hex: "#EBF7EE"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
        )
    }

    // MARK: - Payment Transaction Card View
    @ViewBuilder
    private func paymentCardView(txn: RetailerPaymentTransactionItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Amount + Mode Badge
            HStack {
                Text(String(format: "₹%.2f", txn.amount ?? 0))
                    .font(.system(size: 15.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#167444"))

                Spacer()

                Text(txn.paymentMode?.uppercased() ?? "CASH")
                    .font(.system(size: 10.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color(hex: "#F0F3F1"))
                    .cornerRadius(5)
            }

            // Subtitle
            Text(formatDate(txn.date))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            Divider().background(Color.spiceDivider)

            // Order Details Rows
            VStack(spacing: 6) {
                HStack {
                    Text("Order")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(txn.orderNo ?? "#\(txn.orderId ?? txn.id ?? 0)")
                        .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }

                HStack {
                    Text("Order Date")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(formatDate(txn.orderDate ?? txn.date))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.spiceInk)
                }

                HStack {
                    Text("Discount")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(String(format: "₹%.2f", txn.discount ?? 0))
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }
            }

            // View Order Details Button
            NavigationLink(destination: OrderDetailScreen(orderId: "\(txn.orderId ?? txn.id ?? 0)")) {
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

// MARK: - Payments ViewModel
class PaymentsViewModel: ObservableObject {
    @Published var transactions: [RetailerPaymentTransactionItem] = []
    @Published var summary: RetailerPaymentHistorySummary? = nil
    @Published var isLoading: Bool = false
    @Published var isShowToast: Bool = false
    @Published var toastMessage: String = ""

    private let service = OrderServiceManager()
    private var cancellables = Set<AnyCancellable>()

    func loadPayments() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        service.fetchRetailerPaymentHistory(page: 1, perPage: 20, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.summary = response.summary
                    self?.transactions = response.data?.items ?? []
                }
            }
            .store(in: &cancellables)
    }
}
