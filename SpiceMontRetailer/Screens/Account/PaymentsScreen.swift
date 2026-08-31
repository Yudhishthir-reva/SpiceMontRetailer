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
    @State private var selectedDateRange: DateRange? = nil

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
        let dateText = selectedDateRange?.displayString ?? "All time"
        return "\(modeText), \(dateText)"
    }

    @State private var isShowingSubmitSheet: Bool = false
    @State private var isShowingRequestsListSheet: Bool = false

    var body: some View {
        ZStack {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        // MARK: - 1. Top Make Payment Banner
                        NavigationLink(destination: MakePaymentScreen()) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 40, height: 40)

                                    Image(systemName: "wallet.pass.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Make Payment")
                                        .font(.appFont(size: 15, weight: .heavy))
                                        .foregroundColor(.white)

                                    Text("Pay by UPI, QR or bank transfer")
                                        .font(.appFont(size: 11.5, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                }

                                Spacer()

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.spicePrimary)
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)

                        // MARK: - 2. Action Buttons Row: Submit Request & View Requests
                        HStack(spacing: 12) {
                            Button(action: {
                                isShowingSubmitSheet = true
                            }) {
                                Text("Submit Request")
                                    .font(.appFont(size: 13, weight: .heavy))
                                    .foregroundColor(Color.spicePrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.spicePrimary, lineWidth: 1.2)
                                    )
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                isShowingRequestsListSheet = true
                            }) {
                                Text("View Requests")
                                    .font(.appFont(size: 13, weight: .heavy))
                                    .foregroundColor(Color.spicePrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.spicePrimary, lineWidth: 1.2)
                                    )
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }

                        // MARK: - 3. Total Paid Summary Mint Card
                        totalPaidSummaryCard

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
                                    viewModel.loadPayments(range: nil)
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

                        // MARK: - 4. Payment Mode Filter Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(modeFilters, id: \.self) { mode in
                                    Button(action: {
                                        selectedModeFilter = mode
                                    }) {
                                        Text(mode)
                                            .font(.appFont(size: 12.5, weight: .bold))
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

                        // MARK: - 5. Date Filter (Calendar Sheet)
                        HStack {
                            SpiceDateRangeFilterChip(selectedRange: $selectedDateRange, placeholder: "Any Date")

                            Spacer()

                            if selectedDateRange != nil || selectedModeFilter != "All Modes" {
                                Button(action: {
                                    selectedDateRange = nil
                                    selectedModeFilter = "All Modes"
                                    viewModel.loadPayments(range: nil)
                                }) {
                                    Text("Clear all")
                                        .font(.appFont(size: 12.5, weight: .bold))
                                        .foregroundColor(Color.spicePrimary)
                                }
                            }
                        }

                        // MARK: - 6. Transactions List or Empty State
                        if viewModel.isLoading && viewModel.transactions.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(0..<4, id: \.self) { _ in
                                    SpiceSkeletonBox(height: 180, cornerRadius: 16)
                                }
                            }
                        } else if filteredTransactions.isEmpty {
                            VStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(hex: "#F0F3F1"))
                                        .frame(width: 56, height: 56)

                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.spiceMuted)
                                }
                                .padding(.top, 40)

                                Text("No Payments Yet")
                                    .font(.appFont(size: 17, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)

                                Text("Payments recorded against your orders will appear here.")
                                    .font(.appFont(size: 12.5, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
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
                    viewModel.loadPayments(range: selectedDateRange)
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
                    viewModel.loadPayments(range: selectedDateRange)
                    AppConfigManager.shared.checkStatus()
                }) {
                    Text("Refresh")
                        .font(.appFont(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }
        }
        .onAppear {
            viewModel.loadPayments(range: selectedDateRange)
            AppConfigManager.shared.checkStatus()
        }
        .onChange(of: selectedDateRange) { _, newRange in
            viewModel.loadPayments(range: newRange)
        }
        .sheet(isPresented: $isShowingSubmitSheet) {
            SubmitPaymentRequestSheet()
        }
        .sheet(isPresented: $isShowingRequestsListSheet) {
            PaymentRequestsListSheet()
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
                .font(.appFont(size: 11, weight: .heavy))
                .foregroundColor(Color(hex: "#167444"))
                .tracking(0.5)

            Text(selectedDateRange?.displayString ?? "All time")
                .font(.appFont(size: 11.5, weight: .medium))
                .foregroundColor(Color(hex: "#5B8A6E"))

            Text("₹\(totalPaid)")
                .font(.appFont(size: 32, weight: .heavy, design: .rounded))
                .foregroundColor(Color(hex: "#167444"))

            Divider().background(Color(hex: "#C8E8D2")).padding(.vertical, 2)

            Text("PAID BY")
                .font(.appFont(size: 10, weight: .heavy))
                .foregroundColor(Color(hex: "#5B8A6E"))
                .tracking(0.5)
                .padding(.top, 2)

            ForEach(["Cash", "Cheque", "UPI"], id: \.self) { mode in
                HStack {
                    Text(mode)
                        .font(.appFont(size: 12.5, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text("₹\(modes[mode] ?? "0.00")")
                        .font(.appFont(size: 13, weight: .heavy, design: .monospaced))
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

    // MARK: - Bank & UPI Account Details Card
    @ViewBuilder
    private var accountDetailsCard: some View {
        if let details = AppConfigManager.shared.accountDetails,
           (details.accountName?.isEmpty == false || details.bankName?.isEmpty == false || details.upiId?.isEmpty == false) {
            SpiceCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                            .font(.appFont(size: 14, weight: .bold))
                            .foregroundColor(Color.spicePrimary)
                        Text("Company Bank & Payment Details")
                            .font(.appFont(size: 13, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Spacer()
                    }

                    Divider()

                    if let bank = details.bankName, !bank.isEmpty {
                        SpiceKVRow(key: "Bank Name", value: bank)
                    }
                    if let name = details.accountName, !name.isEmpty {
                        SpiceKVRow(key: "Account Holder", value: name)
                    }
                    if let ifsc = details.ifscCode, !ifsc.isEmpty {
                        SpiceKVRow(key: "IFSC Code", value: ifsc, isMonoValue: true)
                    }
                    if let branch = details.branchName, !branch.isEmpty {
                        SpiceKVRow(key: "Branch", value: branch)
                    }
                    if let upi = details.upiId, !upi.isEmpty {
                        SpiceKVRow(key: "UPI ID", value: upi, isMonoValue: true)
                    }
                }
            }
        }
    }

    // MARK: - Payment Transaction Card View
    @ViewBuilder
    private func paymentCardView(txn: RetailerPaymentTransactionItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top Row: Amount + Mode Badge
            HStack {
                Text(String(format: "₹%.2f", txn.amount ?? 0))
                    .font(.appFont(size: 15.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#167444"))

                Spacer()

                Text(txn.paymentMode?.uppercased() ?? "CASH")
                    .font(.appFont(size: 10.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#6B7280"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color(hex: "#F0F3F1"))
                    .cornerRadius(5)
            }

            // Subtitle
            Text(formatDate(txn.date))
                .font(.appFont(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            Divider().background(Color.spiceDivider)

            // Order Details Rows
            VStack(spacing: 6) {
                HStack {
                    Text("Order")
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(txn.orderNo ?? "#\(txn.orderId ?? txn.id ?? 0)")
                        .font(.appFont(size: 13.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }

                HStack {
                    Text("Order Date")
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(formatDate(txn.orderDate ?? txn.date))
                        .font(.appFont(size: 13, weight: .semibold))
                        .foregroundColor(Color.spiceInk)
                }

                HStack {
                    Text("Discount")
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                    Spacer()
                    Text(String(format: "₹%.2f", txn.discount ?? 0))
                        .font(.appFont(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }
            }

            // View Order Details Button
            NavigationLink(destination: OrderDetailScreen(orderId: "\(txn.orderId ?? txn.id ?? 0)")) {
                HStack {
                    Spacer()
                    Text("View Order Details")
                        .font(.appFont(size: 13, weight: .heavy))
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
        guard let raw = raw, !raw.isEmpty else { return "" }
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd"
        if let d = iso.date(from: String(raw.prefix(10))) {
            let cal = Calendar.current
            if cal.isDateInToday(d) {
                return "Today"
            } else if cal.isDateInYesterday(d) {
                return "Yesterday"
            }
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

    func loadPayments(range: DateRange? = nil) {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        var startDate: String? = nil
        var endDate: String? = nil
        if let range = range, range.isActive {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            startDate = formatter.string(from: range.startDate)
            endDate = formatter.string(from: range.endDate)
        }

        service.fetchRetailerPaymentHistory(page: 1, perPage: 20, startDate: startDate, endDate: endDate, headers: headers)
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
