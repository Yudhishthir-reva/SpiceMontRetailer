//
//  AccountScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct AccountScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLogoutModal: Bool = false
    @State private var showEditPersonalModal: Bool = false
    @State private var showRequestBusinessUpdateModal: Bool = false
    @State private var cancellables = Set<AnyCancellable>()

    private let defaults = UserDefaultManager.shared

    var userName: String {
        let name = defaults.getUserDefaultsString(key: .userName)
        return name.isEmpty ? "Rahul h" : name
    }

    var userMobile: String {
        let mobile = defaults.getUserDefaultsString(key: .userMobile)
        return mobile.isEmpty ? "+91 7737772424" : (mobile.hasPrefix("+91") ? mobile : "+91 \(mobile)")
    }

    var userEmail: String {
        let email = defaults.getUserDefaultsString(key: .userEmail)
        return email.isEmpty ? "empty5108@gmail.com" : email
    }

    var shopName: String {
        let shop = defaults.getUserDefaultsString(key: .shopName)
        return shop.isEmpty ? "Test Bill" : shop
    }

    var whatsappNumber: String {
        let wa = defaults.getUserDefaultsString(key: .whatsappNumber)
        return wa.isEmpty ? userMobile : (wa.hasPrefix("+91") ? wa : "+91 \(wa)")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.spiceBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Top Bar
                    HStack {
                        Text("Profile")
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            // MARK: - Card 1: Retailer Profile Header Card
                            profileHeaderCard

                            // MARK: - Card 2: Personal Information Card
                            personalInfoCard

                            // MARK: - Card 3: Business Information Card
                            businessInfoCard

                            // MARK: - Card 4: Navigation Menu Card
                            menuNavigationCard

                            // MARK: - Card 5: Logout Button
                            Button(action: {
                                showLogoutModal = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Logout")
                                        .font(.system(size: 14, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                }
                                .frame(height: 48)
                                .background(Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.spiceCardBorder, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            // MARK: - Version Text
                            Text("SpiceMonk Business · v1.0.0")
                                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)
                                .padding(.top, 2)
                                .padding(.bottom, 24)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }
                }

                // MARK: - Logout Confirmation Modal
                if showLogoutModal {
                    logoutConfirmationDialog
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Card 1: Profile Header Card
    private var profileHeaderCard: some View {
        HStack(alignment: .center, spacing: 14) {
            // Avatar Logo Box
            ZStack {
                Circle()
                    .fill(Color(hex: "#E8F5EC"))
                    .frame(width: 54, height: 54)

                Image("spice_monk_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(userName)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text(shopName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }

            Spacer()

            Text("APPROVED")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(Color(hex: "#167444"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: "#EAF7EE"))
                .cornerRadius(6)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Card 2: Personal Information Card
    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Personal Information")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Button(action: {
                    showEditPersonalModal = true
                }) {
                    Text("Edit")
                        .font(.system(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }

            VStack(spacing: 8) {
                infoRow(key: "Name", value: userName)
                infoRow(key: "Mobile", value: userMobile, isMono: true)
                infoRow(key: "Email", value: userEmail)
                infoRow(key: "WhatsApp", value: whatsappNumber, isMono: true)
            }

            Text("Mobile number changes require OTP verification.")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .padding(.top, 2)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Card 3: Business Information Card
    private var businessInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Business Information")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                Button(action: {
                    showRequestBusinessUpdateModal = true
                }) {
                    Text("Request Update")
                        .font(.system(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
            }

            infoRow(key: "Shop Name", value: shopName, isBoldValue: true)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Card 4: Navigation Menu Card
    private var menuNavigationCard: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: OrdersScreen()) {
                menuRow(icon: "doc.plaintext.fill", title: "My Orders")
            }
            Divider().background(Color.spiceDivider)

            NavigationLink(destination: SchemesScreen()) {
                menuRow(icon: "tag.fill", title: "Running Schemes")
            }
            Divider().background(Color.spiceDivider)

            NavigationLink(destination: LedgerScreen()) {
                menuRow(icon: "doc.text.fill", title: "Outstanding Ledger")
            }
            Divider().background(Color.spiceDivider)

            NavigationLink(destination: SalesmanScreen()) {
                menuRow(icon: "person.fill", title: "Assigned Salesman")
            }
            Divider().background(Color.spiceDivider)

            NavigationLink(destination: NotificationScreen()) {
                menuRow(icon: "bell.fill", title: "Notifications")
            }
            Divider().background(Color.spiceDivider)

            NavigationLink(destination: CustomerSupportScreen()) {
                menuRow(icon: "headphones", title: "Customer Support")
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Menu Row Item
    private func menuRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.spiceInk)
                .frame(width: 22)

            Text(title)
                .font(.system(size: 13.5, weight: .bold))
                .foregroundColor(Color.spiceInk)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.spiceMuted.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Key-Value Info Row Helper
    private func infoRow(key: String, value: String, isMono: Bool = false, isBoldValue: Bool = false) -> some View {
        HStack {
            Text(key)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            Spacer()

            Text(value)
                .font(
                    isMono ?
                        .system(size: 13, weight: isBoldValue ? .heavy : .semibold, design: .monospaced) :
                        .system(size: 13, weight: isBoldValue ? .heavy : .semibold)
                )
                .foregroundColor(Color.spiceInk)
        }
    }

    // MARK: - Logout Confirmation Dialog
    private var logoutConfirmationDialog: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("Are you sure you want to logout?")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text("You will need to verify your mobile number with an OTP to login again.")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .lineSpacing(2)

                HStack(spacing: 12) {
                    Button(action: {
                        showLogoutModal = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
                            .cornerRadius(10)
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
                .padding(.top, 4)
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(18)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Logout Action
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
