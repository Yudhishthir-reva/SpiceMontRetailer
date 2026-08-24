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
    @State private var totalOutstanding: String = "0.00"
    @State private var runningOrder: Order? = nil
    @State private var recentOrder: Order? = nil
    @State private var availableOffers: [RetailerOfferScheme] = []

    private let defaults = UserDefaultManager.shared
    private let orderService = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var greetingName: String {
        let name = defaults.getUserDefaultsString(key: .userName)
        return name.isEmpty ? "Retailer" : name
    }

    var sellerCode: String {
        let code = defaults.getUserDefaultsString(key: .sellerId)
        return code.isEmpty ? "RET-10245" : code
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Top Bar
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [Color.spicePrimary, Color.spicePrimaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)
                        .overlay(Text("S").font(.system(size: 16, weight: .heavy)).foregroundColor(.white))

                    Text("SpiceMonk")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    Spacer()

                    Button(action: { showNotifications = true }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.spiceInk)
                                .padding(6)

                            Text("3")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.spiceDue)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -2)
                        }
                    }

                    NavigationLink(destination: AccountScreen()) {
                        Circle()
                            .fill(Color.spiceLightGray)
                            .frame(width: 32, height: 32)
                            .overlay(Image(systemName: "person.fill").font(.system(size: 14)).foregroundColor(Color.spiceInk))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // User Info Header
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Welcome, \(greetingName)")
                                .font(.system(size: 19, weight: .heavy))
                                .foregroundColor(Color.spiceInk)
                            Text("Retailer Code: \(sellerCode)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.spiceMuted)
                        }
                        .padding(.top, 4)

                        // Amount Due Green Card (from live ledger API)
                        NavigationLink(destination: LedgerScreen()) {
                            SpiceCard(backgroundColor: Color.spicePrimary, borderColor: Color.spicePrimary, padding: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("TOTAL AMOUNT DUE")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(Color(hex: "#B7E3CB"))
                                        .tracking(0.8)

                                    Text("₹\(totalOutstanding)")
                                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                                        .foregroundColor(.white)

                                    HStack {
                                        Text("View Ledger")
                                            .font(.system(size: 12, weight: .heavy))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Primary "+ PLACE NEW ORDER" Button
                        NavigationLink(destination: BrandSelectionScreen()) {
                            HStack {
                                Text("+ PLACE NEW ORDER")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(.white)
                                    .tracking(0.3)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.spicePrimary)
                            .cornerRadius(13)
                        }

                        // 4-Grid Quick Actions
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            quickActionTile(title: "New Order", icon: "plus.circle.fill", destination: AnyView(BrandSelectionScreen()))
                            quickActionTile(title: "Orders", icon: "bag.fill", destination: AnyView(OrdersScreen()))
                            quickActionTile(title: "Repeat Order", icon: "arrow.triangle.2.circlepath", destination: AnyView(CartScreen()))
                            quickActionTile(title: "Ledger", icon: "doc.text.fill", destination: AnyView(LedgerScreen()))
                        }

                        // Running Order Card (Live from Orders API)
                        if let order = runningOrder {
                            HStack {
                                Text("Running Order")
                                    .font(.system(size: 13.5, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)
                                Spacer()
                                SpiceStatusBadge(status: order.statusLabel.uppercased())
                            }
                            .padding(.top, 4)

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

                        // Running Schemes (Live from Offers API)
                        if !availableOffers.isEmpty {
                            HStack {
                                Text("Running Schemes")
                                    .font(.system(size: 13.5, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)
                                Spacer()
                                NavigationLink(destination: SchemesScreen()) {
                                    Text("View All")
                                        .font(.system(size: 11.5, weight: .heavy))
                                        .foregroundColor(Color.spicePrimary)
                                }
                            }

                            if let scheme = availableOffers.first {
                                NavigationLink(destination: SchemeDetailScreen(scheme: scheme)) {
                                    SpiceCard(padding: 0) {
                                        VStack(alignment: .leading, spacing: 0) {
                                            RoundedRectangle(cornerRadius: 0)
                                                .fill(LinearGradient(colors: [Color(hex: "#C8322B"), Color(hex: "#7C1A16")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(height: 80)
                                                .overlay(
                                                    Text("SPECIAL SCHEME")
                                                        .font(.system(size: 11, weight: .heavy))
                                                        .foregroundColor(.white)
                                                        .padding(8),
                                                    alignment: .bottomLeading
                                                )

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(scheme.title ?? "Trade Scheme")
                                                    .font(.system(size: 13, weight: .heavy))
                                                    .foregroundColor(Color.spiceInk)
                                                Text(scheme.description ?? "")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(Color.spiceMuted)
                                                HStack {
                                                    SpiceStatusBadge(status: scheme.type?.uppercased() ?? "TRADE SCHEME")
                                                    Spacer()
                                                    if let minVal = scheme.minOrderValue {
                                                        Text("Min: ₹\(String(format: "%.0f", minVal))")
                                                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                                            .foregroundColor(Color.spiceMuted)
                                                    }
                                                }
                                                .padding(.top, 2)
                                            }
                                            .padding(12)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Recent Order (Live from Orders API)
                        if let lastOrder = recentOrder {
                            HStack {
                                Text("Recent Orders")
                                    .font(.system(size: 13.5, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)
                                Spacer()
                                NavigationLink(destination: OrdersScreen()) {
                                    Text("View All")
                                        .font(.system(size: 11.5, weight: .heavy))
                                        .foregroundColor(Color.spicePrimary)
                                }
                            }

                            NavigationLink(destination: OrderDetailScreen(orderId: "\(lastOrder.id ?? 0)")) {
                                SpiceCard(padding: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(lastOrder.orderNumberFormatted)
                                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                                .foregroundColor(Color.spiceInk)
                                            Text("\(lastOrder.createdAt ?? "") · \(lastOrder.itemsCount ?? lastOrder.items?.count ?? 0) items · \(lastOrder.total?.priceLabel ?? "₹0")")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(Color.spiceMuted)
                                        }
                                        Spacer()
                                        SpiceStatusBadge(status: lastOrder.statusLabel.uppercased())
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Assigned Salesman & Support Shortcuts
                        NavigationLink(destination: SalesmanScreen()) {
                            SpiceCard(padding: 12) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color(hex: "#1B57D6"), Color(hex: "#123A8E")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                        .overlay(Text("AK").font(.system(size: 10, weight: .heavy)).foregroundColor(.white))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Assigned Salesman")
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundColor(Color.spiceInk)
                                        Text("Contact territory beat representative")
                                            .font(.system(size: 10.5, weight: .medium))
                                            .foregroundColor(Color.spiceMuted)
                                    }

                                    Spacer()

                                    Text("CALL")
                                        .font(.system(size: 9.5, weight: .heavy))
                                        .foregroundColor(Color.spicePrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.spicePrimaryLight)
                                        .cornerRadius(6)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Customer Support
                        NavigationLink(destination: CustomerSupportScreen()) {
                            SpiceCard(padding: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Customer Support")
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundColor(Color.spiceInk)
                                        Text("Mon–Sat, 9 AM – 7 PM")
                                            .font(.system(size: 10.5, weight: .medium))
                                            .foregroundColor(Color.spiceMuted)
                                    }
                                    Spacer()
                                    Text("Call Customer Care")
                                        .font(.system(size: 11.5, weight: .heavy))
                                        .foregroundColor(Color.spicePrimary)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 20)
                    }
                    .padding(16)
                }
                .refreshable {
                    loadLiveDashboard()
                }
                .background(Color.spiceBackground)
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

    private func loadLiveDashboard() {
        let headers = defaults.authHeader

        // 1. Fetch live ledger total outstanding
        orderService.fetchRetailerLedger(page: 1, perPage: 1, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                if let summary = response.summary {
                    self.totalOutstanding = summary.totalPending ?? "0.00"
                }
            })
            .store(in: &cancellables)

        // 2. Fetch live orders (running & recent)
        orderService.fetchOrders(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                let orders = response.orders ?? []
                self.runningOrder = orders.first(where: {
                    let s = ($0.status ?? "").lowercased()
                    return s != "delivered" && s != "cancelled"
                })
                self.recentOrder = orders.first(where: {
                    let s = ($0.status ?? "").lowercased()
                    return s == "delivered" || s == "cancelled"
                })
            })
            .store(in: &cancellables)

        // 3. Fetch live schemes / offers
        orderService.fetchAvailableOffers(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                self.availableOffers = response.data?.schemes ?? []
            })
            .store(in: &cancellables)
    }

    private func quickActionTile(title: String, icon: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            SpiceCard(padding: 10) {
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color.spiceInk)
                    Text(title)
                        .font(.system(size: 9.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }
}
