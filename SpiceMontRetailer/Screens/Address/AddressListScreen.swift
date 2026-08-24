//
//  AddressListScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct AddressListScreen: View {

    var isSelectMode: Bool = false
    var selectedAddressId: Int? = nil
    var onSelectAddress: ((Address) -> Void)? = nil

    @State private var addresses: [Address] = []
    @State private var isLoading = true
    @State private var showAddAddress = false
    @State private var isShowToast = false
    @State private var toastMessage = ""
    @Environment(\.dismiss) private var dismiss

    private let service = AddressServiceManager()

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            SpiceTopBar(
                title: isSelectMode ? "Select Delivery Address" : "Delivery Addresses",
                showBack: true,
                onBack: { dismiss() }
            )

            if isLoading && addresses.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { _ in
                            SpiceSkeletonBox(height: 120, cornerRadius: 14)
                        }
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            } else if addresses.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(addresses) { address in
                            addressCard(address)
                        }
                        Spacer(minLength: 70)
                    }
                    .padding(16)
                }
                .refreshable {
                    loadAddresses()
                }
                .background(Color.spiceBackground)

                // Bottom Add Address Bar
                VStack(spacing: 0) {
                    Divider()
                    SpicePrimaryButton(title: "+ Add New Address", height: 48) {
                        showAddAddress = true
                    }
                    .padding(16)
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear(perform: loadAddresses)
        .sheet(isPresented: $showAddAddress) {
            NavigationStack {
                AddAddressScreen {
                    loadAddresses()
                }
            }
        }
        .toast(isPresenting: $isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Address Card
    private func addressCard(_ address: Address) -> some View {
        let isSelected = selectedAddressId == address.id || (selectedAddressId == nil && address.isDefault == true)

        return SpiceCard(
            backgroundColor: (isSelectMode && isSelected) ? Color.spicePrimaryWash.opacity(0.5) : Color.white,
            borderColor: (isSelectMode && isSelected) ? Color.spicePrimary : Color.spiceCardBorder
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        if isSelectMode {
                            Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isSelected ? Color.spicePrimary : Color.spiceMuted)
                        } else {
                            Image(systemName: address.type?.lowercased() == "office" ? "building.2.fill" : "storefront.fill")
                                .font(.system(size: 13))
                                .foregroundColor(Color.spicePrimary)
                        }

                        Text(address.name ?? "Store Address")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                    }

                    Spacer()

                    if address.isDefault == true {
                        SpiceStatusBadge(status: "DEFAULT")
                    } else if !isSelectMode {
                        Button(action: {
                            setDefault(id: address.id ?? 0)
                        }) {
                            Text("Set Default")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.spicePrimary)
                        }
                    }
                }

                Divider()

                Text(address.fullAddress)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.spiceInk.opacity(0.85))
                    .lineSpacing(2)

                if let phone = address.phone, !phone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.spiceMuted)
                        Text("+91 \(phone)")
                            .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                    }
                }

                if isSelectMode {
                    Divider().padding(.top, 2)

                    SpicePrimaryButton(
                        title: isSelected ? "✓ Deliver to this Address" : "Deliver Here",
                        height: 36
                    ) {
                        onSelectAddress?(address)
                        dismiss()
                    }
                    .padding(.top, 2)
                }
            }
        }
        .onTapGesture {
            if isSelectMode {
                onSelectAddress?(address)
                dismiss()
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Circle()
                .fill(Color.spicePrimaryWash)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 30))
                        .foregroundColor(Color.spicePrimary)
                )

            Text("No Delivery Addresses")
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            Text("Add your shop, godown, or outlet delivery address to receive wholesale orders.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            SpicePrimaryButton(title: "+ Add Address", height: 44) {
                showAddAddress = true
            }
            .frame(width: 180)
            .padding(.top, 8)

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.spiceBackground)
    }

    // MARK: - Network

    private func loadAddresses() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        var cancellables = Set<AnyCancellable>()

        service.fetchAddresses(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { _ in isLoading = false }
            receiveValue: { response in
                addresses = response.addresses ?? []
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { _ = cancellables }
    }

    private func setDefault(id: Int) {
        let headers = UserDefaultManager.shared.authHeader
        var cancellables = Set<AnyCancellable>()

        service.setDefaultAddress(id: id, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            receiveValue: { response in
                if response.status == true {
                    toastMessage = "Default delivery address updated"
                    isShowToast = true
                    loadAddresses()
                }
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { _ = cancellables }
    }
}

#Preview {
    NavigationStack {
        AddressListScreen()
    }
}
