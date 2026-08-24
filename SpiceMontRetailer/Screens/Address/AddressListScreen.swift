//
//  AddressListScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct AddressListScreen: View {

    @State private var addresses: [Address] = []
    @State private var isLoading = true
    @State private var showAddAddress = false
    @State private var isShowToast = false
    @State private var toastMessage = ""

    private let service = AddressServiceManager()

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if addresses.isEmpty {
                emptyState
            } else {
                addressesList
            }
        }
        .background(AppTheme.homeCanvas)
        .spiceNavigationBar(title: "My Addresses")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showAddAddress = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear(perform: loadAddresses)
        .sheet(isPresented: $showAddAddress) {
            NavigationStack {
                AddAddressScreen { loadAddresses() }
            }
        }
        .toast(isPresenting: $isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    private var addressesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(addresses) { address in
                    addressCard(address)
                }
            }
            .padding(16)
        }
    }

    private func addressCard(_ address: Address) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: address.type?.lowercased() == "office" ? "building.2" : "house.fill")
                        .foregroundStyle(AppTheme.brandGreen)
                        .font(.system(size: 14))

                    Text(address.name ?? "Address")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                if address.isDefault == true {
                    Text("DEFAULT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.brandGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                Spacer()

                if address.isDefault != true {
                    Button {
                        setDefault(id: address.id ?? 0)
                    } label: {
                        Text("Set Default")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.brandGreen)
                    }
                }
            }

            Text(address.fullAddress)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSecondary)

            if let phone = address.phone, !phone.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 10))
                    Text(phone)
                        .font(.system(size: 12))
                }
                .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    address.isDefault == true ? AppTheme.brandGreen : AppTheme.cardBorder,
                    lineWidth: address.isDefault == true ? 1.5 : 1
                )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "mappin.slash")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.textMuted.opacity(0.4))

            Text("No addresses saved")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Add a delivery address to get started")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textSecondary)

            Button { showAddAddress = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Address")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 44)
                .background(AppTheme.ctaGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.top, 8)
            Spacer()
        }
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
                    toastMessage = "Default address updated"
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
