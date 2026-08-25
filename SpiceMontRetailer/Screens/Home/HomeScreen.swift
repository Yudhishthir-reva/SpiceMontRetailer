//
//  HomeScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct HomeScreen: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showNotifications: Bool = false

    // Live Dashboard States
    @State private var totalOutstanding: String = "82,103.70"
    @State private var recentOrdersList: [Order] = []
    @State private var salesmanName: String = "Laxman SP"
    @State private var salesmanPhone: String = "9988776655"

    private let defaults = UserDefaultManager.shared
    private let orderService = OrderServiceManager()
    private let homeService = HomeServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var greetingName: String {
        let name = defaults.getUserDefaultsString(key: .userName)
        return name.isEmpty ? "Rahul" : name
    }

    var timeBasedGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        if hour < 12 {
            timeGreeting = "Good Morning"
        } else if hour < 17 {
            timeGreeting = "Good Afternoon"
        } else {
            timeGreeting = "Good Evening"
        }
        return "\(timeGreeting), \(greetingName)"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Header Top Bar
                HStack(spacing: 10) {
                    Image("spice_monk_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("SpiceMonk")
                            .font(.system(size: 16.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Text("BUSINESS")
                            .font(.system(size: 9.5, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                            .tracking(1.0)
                    }

                    Spacer()

                    // Refresh Button
                    Button(action: {
                        loadLiveDashboard()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .padding(6)
                    }

                    // Notifications Button
                    Button(action: {
                        showNotifications = true
                    }) {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.spiceInk)
                            .padding(6)
                    }

                    // Account Button
                    NavigationLink(destination: AccountScreen()) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 21, weight: .regular))
                            .foregroundColor(Color.spiceInk)
                            .padding(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                if viewModel.isAccountPending {
                    accountPendingStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // MARK: - Greeting Header
                            VStack(alignment: .leading, spacing: 3) {
                                Text(timeBasedGreeting)
                                    .font(.system(size: 21, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)

                                Text("Salesman: \(salesmanName)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                            }
                            .padding(.top, 4)

                            // MARK: - Total Amount Due Card
                            NavigationLink(destination: LedgerScreen()) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("TOTAL AMOUNT DUE")
                                        .font(.system(size: 10.5, weight: .bold))
                                        .foregroundColor(Color(hex: "#A8E5C4"))
                                        .tracking(0.6)

                                    Text("₹\(totalOutstanding)")
                                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                                        .foregroundColor(.white)

                                    HStack {
                                        Text("View Ledger")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.16))
                                    .cornerRadius(10)
                                }
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#0E763D"), Color(hex: "#075429")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)

                            // MARK: - Place New Order Banner Card
                            NavigationLink(destination: BrandSelectionScreen()) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.white.opacity(0.18))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 15, weight: .heavy))
                                                .foregroundColor(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Place New Order")
                                            .font(.system(size: 15, weight: .heavy))
                                            .foregroundColor(.white)

                                        Text("Browse brands and build your order")
                                            .font(.system(size: 11.5, weight: .medium))
                                            .foregroundColor(Color.white.opacity(0.85))
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "#0F7C40"), Color(hex: "#0A5F31")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)

                            // MARK: - 3 Quick Action Cards
                            HStack(spacing: 10) {
                                // 1. New Order
                                NavigationLink(destination: BrandSelectionScreen()) {
                                    VStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: "#E8F8EE"))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "cart.badge.plus")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(Color(hex: "#167E46"))
                                            )

                                        Text("New Order")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color.spiceInk)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)

                                // 2. Orders
                                NavigationLink(destination: OrdersScreen()) {
                                    VStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: "#EBF3FE"))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "doc.text")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(Color(hex: "#2563EB"))
                                            )

                                        Text("Orders")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color.spiceInk)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)

                                // 3. Ledger
                                NavigationLink(destination: LedgerScreen()) {
                                    VStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(hex: "#FEECEB"))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "doc.plaintext")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(Color(hex: "#DC2626"))
                                            )

                                        Text("Ledger")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color.spiceInk)
                                    }
                                    .frame(maxWidth: .infinity)
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

                            // MARK: - Recent Orders Section
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Recent Orders")
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)

                                    Spacer()

                                    NavigationLink(destination: OrdersScreen()) {
                                        Text("View All")
                                            .font(.system(size: 12.5, weight: .heavy))
                                            .foregroundColor(Color.spicePrimary)
                                    }
                                }

                                if recentOrdersList.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "list.clipboard")
                                            .font(.system(size: 24))
                                            .foregroundColor(Color.spiceMuted.opacity(0.4))
                                        Text("No Recent Orders")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color.spiceInk)
                                        Text("Your recently placed orders will appear here.")
                                            .font(.system(size: 11.5, weight: .medium))
                                            .foregroundColor(Color.spiceMuted)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color.white)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.spiceCardBorder, lineWidth: 1)
                                    )
                                } else {
                                    ForEach(recentOrdersList.prefix(5)) { order in
                                        NavigationLink(destination: OrderDetailScreen(orderId: "\(order.id ?? 0)")) {
                                            recentOrderCard(
                                                orderNumber: order.orderNumberFormatted,
                                                date: order.displayDateOnly,
                                                amount: order.total?.priceLabel ?? "₹0.00",
                                                status: order.statusLabel.uppercased()
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            // MARK: - My Salesman Section
                            VStack(alignment: .leading, spacing: 10) {
                                Text("My Salesman")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)

                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#3B82F6"), Color(hex: "#1D4ED8")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(salesmanName)
                                            .font(.system(size: 14.5, weight: .heavy))
                                            .foregroundColor(Color.spiceInk)
                                    }

                                    Spacer()

                                    Button(action: {
                                        if let url = URL(string: "tel://\(salesmanPhone)") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: "phone.fill")
                                                .font(.system(size: 10, weight: .bold))
                                            Text("CALL")
                                                .font(.system(size: 11, weight: .heavy))
                                        }
                                        .foregroundColor(Color.spicePrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.spicePrimaryLight)
                                        .cornerRadius(6)
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

                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                    .refreshable {
                        loadLiveDashboard()
                    }
                    .background(Color.spiceBackground)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotifications) {
                NavigationStack { NotificationScreen() }
            }
            .onAppear {
                loadLiveDashboard()
            }
        }
    }

    // MARK: - Recent Order Card Component
    private func recentOrderCard(orderNumber: String, date: String, amount: String, status: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(orderNumber)
                    .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Text(status)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#B87314"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#FEF4E6"))
                    .cornerRadius(5)
            }

            HStack(spacing: 6) {
                Text(date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.spiceMuted)

                Text("·")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.spiceMuted)

                Text(amount)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.spiceMuted)
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

    // MARK: - Live Dashboard Fetch
    private func loadLiveDashboard() {
        let headers = defaults.authHeader

        // 1. Fetch live ledger total outstanding
        orderService.fetchRetailerLedger(page: 1, perPage: 1, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                if let summary = response.summary, let pending = summary.totalPending, !pending.isEmpty {
                    self.totalOutstanding = pending
                }
            })
            .store(in: &cancellables)

        // 2. Fetch live orders
        orderService.fetchOrders(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                if let orders = response.orders, !orders.isEmpty {
                    self.recentOrdersList = orders
                }
            })
            .store(in: &cancellables)

        // 3. Fetch retailer home info (salesman, widgets, account status)
        homeService.fetchRetailerHome(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                self.viewModel.isAccountPending = (response.accountStatus?.lowercased() == "pending")
                self.viewModel.accountPendingMessage = response.message ?? ""

                if let widgets = response.widgets {
                    for w in widgets {
                        if let s = w.salesman {
                            if let name = s.name, !name.isEmpty {
                                self.salesmanName = name
                            }
                            if let contact = s.contact ?? s.phone ?? s.mobile, !contact.isEmpty {
                                self.salesmanPhone = contact
                            }
                        }
                        if let l = w.ledgerSummary, let pending = l.pendingAmount, !pending.isEmpty {
                            self.totalOutstanding = pending
                        }
                    }
                }
            })
            .store(in: &cancellables)
    }

    // MARK: - Account Pending State
    @ViewBuilder
    private var accountPendingStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Circle()
                .fill(Color.spiceAmberLight)
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "hourglass")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.spiceAmber)
                )

            SpiceStatusBadge(status: "PENDING_REVIEW")

            Text("Your Account is Under Review")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Color.spiceInk)
                .multilineTextAlignment(.center)

            Text(viewModel.accountPendingMessage.isEmpty ? "Your retailer registration has been submitted and is being reviewed by our team. You will be able to place orders once approved." : viewModel.accountPendingMessage)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)

            SpiceOutlinedButton(title: "Contact Support", icon: "phone.fill", color: Color.spicePrimary, height: 42) {
                if let url = URL(string: "tel://18002004455") {
                    UIApplication.shared.open(url)
                }
            }
            .frame(width: 200)
            .padding(.top, 8)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.spiceBackground)
    }
}
