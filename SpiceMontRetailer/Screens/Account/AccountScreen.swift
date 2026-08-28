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
    @State private var profileData: RetailerProfileData? = nil
    @State private var isLoadingProfile: Bool = false
    @State private var showLogoutModal: Bool = false
    @State private var cancellables = Set<AnyCancellable>()

    private let defaults = UserDefaultManager.shared

    var displayName: String {
        let name = profileData?.name ?? defaults.getUserDefaultsString(key: .userName)
        return name.isEmpty ? "Rahul h" : name
    }

    var displayShopName: String {
        let shop = profileData?.shopName ?? defaults.getUserDefaultsString(key: .shopName)
        return shop.isEmpty ? "Test Bill" : shop
    }

    var displayMobile: String {
        let mobile = profileData?.mobile ?? defaults.getUserDefaultsString(key: .userMobile)
        if mobile.isEmpty { return "+91 7737772424" }
        return mobile.hasPrefix("+91") ? mobile : "+91 \(mobile)"
    }

    var displayEmail: String {
        let email = profileData?.email ?? defaults.getUserDefaultsString(key: .userEmail)
        return email.isEmpty ? "empty5108@gmail.com" : email
    }

    var displayWhatsApp: String {
        let wa = profileData?.whatsappNo ?? defaults.getUserDefaultsString(key: .whatsappNumber)
        if wa.isEmpty { return displayMobile }
        return wa.hasPrefix("+91") ? wa : "+91 \(wa)"
    }

    var displayAddress: String {
        let addr = profileData?.address ?? defaults.getUserDefaultsString(key: .shopAddress)
        return addr.isEmpty ? "plot no 215, near elwood school, aman baag 40 ft road, Railway Officers Colony, Kanakpura, Jaipur, Rajasthan 302012" : addr
    }

    var displayGstNo: String {
        let gst = profileData?.gstNo ?? defaults.getUserDefaultsString(key: .gstNo)
        return gst.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayProfilePic: String {
        profileData?.profilePic ?? defaults.getUserDefaultsString(key: .profilePic)
    }

    var isApproved: Bool {
        if let s = profileData?.status {
            return s == 1
        }
        return true
    }

    var body: some View {
        ZStack {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
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
                            HStack(spacing: 8) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.appFont(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#C8322B"))

                                Text("Logout Account")
                                    .font(.appFont(size: 14, weight: .heavy))
                                    .foregroundColor(Color(hex: "#C8322B"))
                            }
                            .frame(maxWidth: .infinity)
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
                            .font(.appFont(size: 11.5, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                            .padding(.top, 2)
                            .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                }
            }

            // MARK: - Logout Confirmation Modal
            if showLogoutModal {
                logoutConfirmationDialog
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            fetchProfile()
        }
    }

    // MARK: - Card 1: Profile Header Card
    private var profileHeaderCard: some View {
        HStack(alignment: .center, spacing: 14) {
            // Avatar Box
            ZStack {
                if !displayProfilePic.isEmpty {
                    RemoteImage(url: displayProfilePic, contentMode: .fill)
                        .frame(width: 54, height: 54)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1))
                } else {
                    Circle()
                        .fill(Color(hex: "#E8F5EC"))
                        .frame(width: 54, height: 54)
                        .overlay(
                            Image("spice_monk_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                        )
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.appFont(size: 17, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text(displayShopName)
                    .font(.appFont(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }

            Spacer()

            if isApproved {
                Text("APPROVED")
                    .font(.appFont(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "#167444"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#EAF7EE"))
                    .cornerRadius(6)
            } else {
                Text("PENDING")
                    .font(.appFont(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceAmber)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.spiceAmberLight)
                    .cornerRadius(6)
            }
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
            Text("Personal Information")
                .font(.appFont(size: 15, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            VStack(spacing: 10) {
                infoRow(key: "Name", value: displayName)
                infoRow(key: "Mobile", value: displayMobile, isMono: true)
                infoRow(key: "Email", value: displayEmail)
                infoRow(key: "WhatsApp", value: displayWhatsApp, isMono: true)
            }

            Text("To change any of your profile details, please ask SpiceMonk admin.")
                .font(.appFont(size: 11.5, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .lineSpacing(2)
                .padding(.top, 4)
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
            Text("Business Information")
                .font(.appFont(size: 15, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            VStack(spacing: 10) {
                infoRow(key: "Shop Name", value: displayShopName)
                infoRow(key: "Address", value: displayAddress, multiline: true)
                if !displayGstNo.isEmpty {
                    infoRow(key: "GSTIN", value: displayGstNo, isMono: true)
                }
                infoRow(key: "KYC Status", value: "VERIFIED", isBoldValue: true)
            }

            Text("To change any of your profile details, please ask SpiceMonk admin.")
                .font(.appFont(size: 11.5, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .lineSpacing(2)
                .padding(.top, 4)
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
            NavigationLink(destination: OrdersScreen().toolbar(.hidden, for: .tabBar)) {
                menuRow(icon: "doc.plaintext.fill", title: "My Orders")
            }
            Divider().background(Color.spiceDivider)

            NavigationLink(destination: SchemesScreen()) {
                menuRow(icon: "tag.fill", title: "Running Schemes")
            }
            Divider().background(Color.spiceDivider)

            NavigationLink(destination: LedgerScreen().toolbar(.hidden, for: .tabBar)) {
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
                .font(.appFont(size: 14, weight: .semibold))
                .foregroundColor(Color.spiceInk)
                .frame(width: 22)

            Text(title)
                .font(.appFont(size: 13.5, weight: .bold))
                .foregroundColor(Color.spiceInk)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.appFont(size: 12, weight: .bold))
                .foregroundColor(Color.spiceMuted.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Key-Value Info Row Helper
    private func infoRow(key: String, value: String, isMono: Bool = false, isBoldValue: Bool = false, multiline: Bool = false) -> some View {
        HStack(alignment: multiline ? .top : .center, spacing: 12) {
            Text(key)
                .font(.appFont(size: 13, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .frame(width: multiline ? 80 : nil, alignment: .leading)

            Spacer()

            Text(value)
                .font(
                    isMono ?
                        .appFont(size: 13, weight: isBoldValue ? .heavy : .semibold, design: .monospaced) :
                        .appFont(size: 13, weight: isBoldValue ? .heavy : .semibold)
                )
                .foregroundColor(Color.spiceInk)
                .multilineTextAlignment(multiline ? .trailing : .trailing)
                .fixedSize(horizontal: false, vertical: multiline)
        }
    }

    // MARK: - API Fetch Profile
    private func fetchProfile() {
        let headers = defaults.authHeader
        guard !headers.isEmpty else { return }
        isLoadingProfile = true
        LoginServiceManager().fetchRetailerProfile(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                isLoadingProfile = false
            } receiveValue: { response in
                if response.status == true, let data = response.data {
                    self.profileData = data

                    if let name = data.name, !name.isEmpty { defaults.setUserDefaultsString(value: name, key: .userName) }
                    if let shop = data.shopName, !shop.isEmpty { defaults.setUserDefaultsString(value: shop, key: .shopName) }
                    if let addr = data.address, !addr.isEmpty { defaults.setUserDefaultsString(value: addr, key: .shopAddress) }
                    if let mob = data.mobile, !mob.isEmpty { defaults.setUserDefaultsString(value: mob, key: .userMobile) }
                    if let wa = data.whatsappNo, !wa.isEmpty { defaults.setUserDefaultsString(value: wa, key: .whatsappNumber) }
                    if let em = data.email, !em.isEmpty { defaults.setUserDefaultsString(value: em, key: .userEmail) }
                    if let pic = data.profilePic, !pic.isEmpty { defaults.setUserDefaultsString(value: pic, key: .profilePic) }
                    if let gst = data.gstNo, !gst.isEmpty { defaults.setUserDefaultsString(value: gst, key: .gstNo) }
                    if let sId = data.sellerId, !sId.isEmpty { defaults.setUserDefaultsString(value: sId, key: .sellerId) }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Logout Confirmation Dialog
    private var logoutConfirmationDialog: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                Text("Are you sure you want to logout?")
                    .font(.appFont(size: 16, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text("You will need to verify your mobile number with an OTP to login again.")
                    .font(.appFont(size: 12.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .lineSpacing(2)

                HStack(spacing: 12) {
                    Button(action: {
                        showLogoutModal = false
                    }) {
                        Text("Cancel")
                            .font(.appFont(size: 13, weight: .bold))
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
                            .font(.appFont(size: 13, weight: .heavy))
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
