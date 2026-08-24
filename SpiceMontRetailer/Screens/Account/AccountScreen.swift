import SwiftUI
import Combine

struct AccountScreen: View {
    @State private var showLogoutModal: Bool = false
    @State private var showNotifications: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    private let defaults = UserDefaultManager.shared

    var userName: String {
        let name = defaults.getUserDefaultsString(key: .userName)
        return name.isEmpty ? "Rahul Sharma" : name
    }

    var userMobile: String {
        let mobile = defaults.getUserDefaultsString(key: .userMobile)
        return mobile.isEmpty ? "98765 43210" : mobile
    }

    var retailerCode: String {
        let sellerId = defaults.getUserDefaultsString(key: .sellerId)
        return sellerId.isEmpty ? "RET-10245" : sellerId
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text("Profile")
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
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                ScrollView {
                    VStack(spacing: 12) {
                        // Profile Header Card
                        SpiceCard {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(LinearGradient(colors: [Color.spicePrimary, Color.spicePrimaryDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 54, height: 54)
                                    .overlay(Text("RS").font(.system(size: 16, weight: .heavy)).foregroundColor(.white))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(userName)
                                        .font(.system(size: 15, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Text("ABC General Store")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.spiceInk.opacity(0.8))
                                    Text(retailerCode)
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                        .foregroundColor(Color.spiceMuted)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 6) {
                                    SpiceStatusBadge(status: "APPROVED")
                                    Text("Edit Profile")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(Color.spicePrimary)
                                }
                            }
                        }

                        // Personal Information Card
                        SpiceCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Personal Information")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                    Text("Edit")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(Color.spicePrimary)
                                }
                                Divider()
                                SpiceKVRow(key: "Name", value: userName)
                                SpiceKVRow(key: "Email", value: "rahul.sharma@abcstore.in")
                                SpiceKVRow(key: "Mobile", value: "+91 \(userMobile)", isMonoValue: true)
                                SpiceKVRow(key: "WhatsApp", value: "+91 \(userMobile)", isMonoValue: true)
                                Text("Mobile number changes require OTP verification.")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                                    .padding(.top, 2)
                            }
                        }

                        // Business Information Card
                        SpiceCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Business Information")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                    Text("Request Update")
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundColor(Color.spicePrimary)
                                }
                                Divider()
                                SpiceKVRow(key: "Shop Name", value: "ABC General Store")
                                SpiceKVRow(key: "GST Number", value: "27ABCDE1234F1Z5", isMonoValue: true)
                                SpiceKVRow(key: "Address", value: "Shop 14, Krishna Market, Andheri East")
                                SpiceKVRow(key: "City / State", value: "Mumbai, Maharashtra")
                                HStack {
                                    Text("KYC Status").font(.system(size: 12, weight: .semibold)).foregroundColor(Color.spiceMuted)
                                    Spacer()
                                    SpiceStatusBadge(status: "VERIFIED")
                                }
                            }
                        }

                        // Assigned Salesman Card
                        NavigationLink(destination: SalesmanScreen()) {
                            SpiceCard {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color(hex: "#1B57D6"), Color(hex: "#123A8E")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 40, height: 40)
                                        .overlay(Text("AK").font(.system(size: 10, weight: .heavy)).foregroundColor(.white))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Amit Kumar")
                                            .font(.system(size: 12.5, weight: .heavy))
                                            .foregroundColor(Color.spiceInk)
                                        Text("Assigned Salesman · Andheri Beat 4")
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(Color.spiceMuted)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(Color.spiceMuted)
                                }
                            }
                        }
                        .buttonStyle(.plain)

                        // Menu Links Card
                        SpiceCard(padding: 0) {
                            VStack(spacing: 0) {
                                NavigationLink(destination: OrdersScreen()) {
                                    menuRowItem(title: "My Orders")
                                }
                                Divider()
                                NavigationLink(destination: LedgerScreen()) {
                                    menuRowItem(title: "Outstanding Ledger")
                                }
                                Divider()
                                NavigationLink(destination: AddressListScreen()) {
                                    menuRowItem(title: "Delivery Addresses")
                                }
                                Divider()
                                NavigationLink(destination: NotificationScreen()) {
                                    menuRowItem(title: "Notifications")
                                }
                                Divider()
                                NavigationLink(destination: CustomerSupportScreen()) {
                                    menuRowItem(title: "Customer Support")
                                }
                            }
                        }

                        // Logout Button
                        SpiceOutlinedButton(title: "Logout", color: Color.spiceDue, height: 48) {
                            showLogoutModal = true
                        }
                        .padding(.top, 4)

                        // Version text
                        Text("SpiceMonk Retailer · v1.0.0")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                            .padding(.vertical, 8)
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            }

            // Logout Confirmation Dialog
            if showLogoutModal {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()

                    SpiceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Are you sure you want to logout?")
                                .font(.system(size: 15, weight: .heavy))
                                .foregroundColor(Color.spiceInk)

                            Text("You will need to verify your mobile number with an OTP to login again.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                                .lineSpacing(2)

                            HStack(spacing: 10) {
                                SpiceGhostButton(title: "Cancel", height: 42) {
                                    showLogoutModal = false
                                }

                                Button(action: {
                                    showLogoutModal = false
                                    performLogout()
                                }) {
                                    Text("Logout")
                                        .font(.system(size: 13, weight: .heavy))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 42)
                                        .background(Color.spiceDue)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showNotifications) {
            NavigationStack { NotificationScreen() }
        }
    }

    private func menuRowItem(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(Color.spiceInk)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.spiceMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private func performLogout() {
        let headers = defaults.authHeader
        LoginServiceManager().logoutRetailer(headers: headers)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        defaults.resetUserData()
        CartManager.shared.items = []
        AppRootManager.shared.setRootView(view: LoginScreen())
    }
}
