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

    private let defaults = UserDefaultManager.shared
    private let orderService = OrderServiceManager()
    private let homeService = HomeServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var greetingText: String {
        let greet = viewModel.greeting.isEmpty ? "Welcome" : viewModel.greeting
        let name = viewModel.sellerName.isEmpty ? defaults.getUserDefaultsString(key: .userName) : viewModel.sellerName
        return name.isEmpty ? greet : "\(greet), \(name)"
    }

    var shopNameText: String {
        let shop = viewModel.shopName.isEmpty ? defaults.getUserDefaultsString(key: .shopName) : viewModel.shopName
        return shop
    }

    var addressText: String {
        viewModel.address.isEmpty ? defaults.getUserDefaultsString(key: .shopAddress) : viewModel.address
    }

    var sellerCodeText: String {
        let code = viewModel.sellerId.isEmpty ? defaults.getUserDefaultsString(key: .sellerId) : viewModel.sellerId
        return code
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
                        VStack(alignment: .leading, spacing: 14) {
                            // MARK: - Retailer Info Header Card
                            retailerProfileCard

                            // MARK: - Dynamic Server Widgets
                            if !viewModel.retailerWidgets.isEmpty {
                                ForEach(viewModel.retailerWidgets) { widget in
                                    dynamicWidgetView(for: widget)
                                }
                            } else if viewModel.isLoading {
                                // Clean Loading Indicator while fetching server widgets
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding(.vertical, 40)
                                    Spacer()
                                }
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

    // MARK: - Dynamic Widget Switcher
    @ViewBuilder
    private func dynamicWidgetView(for widget: RetailerWidget) -> some View {
        switch widget.type {
        case "ledger_summary":
            if let ledger = widget.ledgerSummary {
                ledgerSummaryCard(data: ledger, title: widget.title ?? "Ledger Summary")
            }
        case "place_new_order":
            if let placeOrder = widget.placeOrderLabel {
                placeNewOrderCard(data: placeOrder)
            }
        case "quick_action":
            if let actions = widget.quickActions, !actions.isEmpty {
                quickActionsSection(items: actions, title: widget.title ?? "Quick Actions")
            }
        case "running_order":
            if let running = widget.runningOrder {
                runningOrderSection(orderData: running, title: widget.title ?? "Running Orders")
            }
        case "banner":
            if let banners = widget.banners, !banners.isEmpty {
                topBannersSection(banners: banners, title: widget.title ?? "Top Banners")
            }
        case "recent_order":
            if let recent = widget.recentOrders, !recent.isEmpty {
                recentOrdersSection(orders: recent, title: widget.title ?? "Recent Orders")
            }
        case "salesman":
            if let salesman = widget.salesman {
                mySalesmanSection(data: salesman, title: widget.title ?? "My Salesman")
            }
        case "customer_support":
            if let support = widget.customerSupport {
                customerSupportSection(data: support, title: widget.title ?? "Customer Support")
            }
        default:
            EmptyView()
        }
    }

    // MARK: - 1. Retailer Profile Header Card
    private var retailerProfileCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#E8F5EC"))
                        .frame(width: 48, height: 48)

                    if !viewModel.profilePic.isEmpty {
                        RemoteImage(url: viewModel.profilePic, contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Image("spice_monk_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(greetingText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)

                    Text(shopNameText)
                        .font(.system(size: 16.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    if !addressText.isEmpty {
                        Text(addressText)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color.spiceMuted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
            }

            // Badges Row
            if !sellerCodeText.isEmpty || !viewModel.salesmanName.isEmpty {
                HStack(spacing: 8) {
                    if !sellerCodeText.isEmpty {
                        Text(sellerCodeText)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#374151"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#F3F4F6"))
                            .cornerRadius(6)
                    }

                    if !viewModel.salesmanName.isEmpty {
                        Text("Salesman: \(viewModel.salesmanName)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: "#374151"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#F3F4F6"))
                            .cornerRadius(6)
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

    // MARK: - 2. Ledger Summary Card
    private func ledgerSummaryCard(data: RetailerLedgerData, title: String) -> some View {
        let pendingStr = data.pendingAmount ?? "0"
        let billedStr = data.totalAmount ?? "0"
        let paidStr = data.paidAmount ?? "0"

        return NavigationLink(destination: LedgerScreen()) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title.uppercased())
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(Color(hex: "#A8E5C4"))
                    .tracking(0.6)

                VStack(alignment: .leading, spacing: 2) {
                    Text("₹\(formatCurrency(pendingStr))")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("Pending")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.85))
                }

                // Two Column Breakdown
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TOTAL BILLED")
                            .font(.system(size: 9.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#A8E5C4"))
                            .tracking(0.5)

                        Text("₹\(formatCurrency(billedStr))")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 3) {
                        Text("PAID")
                            .font(.system(size: 9.5, weight: .heavy))
                            .foregroundColor(Color(hex: "#A8E5C4"))
                            .tracking(0.5)

                        Text("₹\(formatCurrency(paidStr))")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.12))
                .cornerRadius(10)

                // View Ledger Action Bar
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
    }

    // MARK: - 3. Place New Order Banner Card
    private func placeNewOrderCard(data: RetailerPlaceOrderData) -> some View {
        let labelText = data.label ?? "+ Place New Order"
        let cleanLabel = labelText.replacingOccurrences(of: "+ ", with: "")
        let bgColor = (data.color != nil && !data.color!.isEmpty) ? Color(hex: data.color!) : Color(hex: "#0F7C40")

        return NavigationLink(destination: BrandSelectionScreen()) {
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
                    Text(cleanLabel)
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
                    colors: [bgColor, bgColor.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Quick Actions Section
    private func quickActionsSection(items: [RetailerQuickActionItem], title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            HStack(spacing: 10) {
                ForEach(items) { action in
                    quickActionItemView(action: action)
                }
            }
        }
    }

    @ViewBuilder
    private func quickActionItemView(action: RetailerQuickActionItem) -> some View {
        let type = action.actionType?.lowercased() ?? ""
        let label = action.label ?? type

        Group {
            if type == "orders" || type == "order" {
                NavigationLink(destination: OrdersScreen()) {
                    quickActionTile(label: label, imageUrl: action.image, fallbackIcon: "doc.text", bgHex: "#EEF2FF", tintHex: "#4F46E5")
                }
            } else if type == "ledger" {
                NavigationLink(destination: LedgerScreen()) {
                    quickActionTile(label: label, imageUrl: action.image, fallbackIcon: "book.closed", bgHex: "#FEF3C7", tintHex: "#D97706")
                }
            } else {
                NavigationLink(destination: BrandSelectionScreen()) {
                    quickActionTile(label: label, imageUrl: action.image, fallbackIcon: "cart", bgHex: "#E8F8EE", tintHex: "#167E46")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func quickActionTile(label: String, imageUrl: String?, fallbackIcon: String, bgHex: String, tintHex: String) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: bgHex))
                .frame(width: 44, height: 44)
                .overlay(
                    Group {
                        if let img = imageUrl, !img.isEmpty {
                            RemoteImage(url: img, contentMode: .fit)
                                .frame(width: 26, height: 26)
                        } else {
                            Image(systemName: fallbackIcon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color(hex: tintHex))
                        }
                    }
                )

            Text(label)
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

    // MARK: - 5. Running Orders Section
    private func runningOrderSection(orderData: RetailerOrderData, title: String) -> some View {
        let orderNum = orderData.orderId ?? ""
        let dateStr = orderData.date ?? ""
        let priceStr = formatCurrency(orderData.totalPrice ?? "0")
        let statusStr = (orderData.status ?? "Pending").uppercased()

        return VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(orderNum)
                        .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)

                    Spacer()

                    Text(statusStr)
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color(hex: "#B87314"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "#FEF4E6"))
                        .cornerRadius(5)
                }

                HStack(spacing: 6) {
                    if !dateStr.isEmpty {
                        Text(dateStr)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)

                        Text("·")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Text("₹\(priceStr)")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.spiceMuted)
                }

                // Action Buttons Row
                HStack(spacing: 10) {
                    NavigationLink(destination: DeliveryTrackingScreen(orderId: orderData.idNum, orderNumber: orderNum)) {
                        Text("Track Order")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.spicePrimary)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: OrderDetailScreen(orderId: orderData.idNum, orderNumber: orderNum)) {
                        Text("View Details")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.spiceCardBorder, lineWidth: 1)
                            )
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
            )
        }
    }

    // MARK: - 6. Top Banners Section
    private func topBannersSection(banners: [RetailerBannerItem], title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(banners) { banner in
                        RemoteImage(url: banner.image, contentMode: .fill)
                            .frame(width: 300, height: 140)
                            .clipped()
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - 7. Recent Orders Section
    private func recentOrdersSection(orders: [RetailerOrderData], title: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                NavigationLink(destination: OrdersScreen()) {
                    Text("View All")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }

            VStack(spacing: 8) {
                ForEach(orders.prefix(5)) { order in
                    let orderNum = order.orderId ?? ""
                    NavigationLink(destination: OrderDetailScreen(orderId: order.idNum, orderNumber: orderNum)) {
                        recentOrderCard(
                            orderNumber: orderNum,
                            date: order.date ?? "",
                            amount: "₹\(formatCurrency(order.totalPrice ?? "0"))",
                            status: (order.status ?? "PENDING").uppercased()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 8. My Salesman Section
    private func mySalesmanSection(data: RetailerSalesmanData, title: String) -> some View {
        let name = data.name ?? viewModel.salesmanName
        let phone = data.contact ?? data.phone ?? data.mobile ?? viewModel.salesmanPhone

        return VStack(alignment: .leading, spacing: 10) {
            Text(title)
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
                    Text(name)
                        .font(.system(size: 14.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    if !phone.isEmpty {
                        Text(phone)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }
                }

                Spacer()

                if !phone.isEmpty {
                    Button(action: {
                        if let url = URL(string: "tel://\(phone)") {
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
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
            )
        }
    }

    // MARK: - 9. Customer Support Section
    private func customerSupportSection(data: RetailerSupportData, title: String) -> some View {
        let phone = data.contact ?? viewModel.customerSupportPhone

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                if !phone.isEmpty {
                    Text(phone)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
            }

            Spacer()

            if !phone.isEmpty {
                Button(action: {
                    if let url = URL(string: "tel://\(phone)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Call Customer Care")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
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
                if !date.isEmpty {
                    Text(date)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)

                    Text("·")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.spiceMuted)
                }

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

    // MARK: - Helpers
    private func formatCurrency(_ value: String) -> String {
        let clean = value.replacingOccurrences(of: "₹", with: "").replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces)
        guard let dVal = Double(clean) else { return value }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: dVal)) ?? value
    }

    // MARK: - Live Dashboard Fetch
    private func loadLiveDashboard() {
        viewModel.loadHome()
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
                if let url = URL(string: "tel://\(viewModel.customerSupportPhone)") {
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

#Preview {
    HomeScreen()
}
