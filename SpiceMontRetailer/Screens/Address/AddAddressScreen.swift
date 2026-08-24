//
//  AddAddressScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct AddAddressScreen: View {

    var onSaved: (() -> Void)?

    @State private var name = ""
    @State private var phone = ""
    @State private var pincode = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var landmark = ""
    @State private var city = ""
    @State private var state = ""
    @State private var addressType = "home"
    @State private var isSaving = false
    @State private var isFetchingCity = false
    @State private var isShowToast = false
    @State private var toastMessage = ""
    @Environment(\.dismiss) private var dismiss

    private let service = AddressServiceManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Name
                formField(title: "FULL NAME", text: $name, placeholder: "Enter full name")

                // Phone
                formField(title: "PHONE NUMBER", text: $phone, placeholder: "10-digit mobile", keyboard: .numberPad)
                    .onChange(of: phone) { _, newValue in
                        phone = String(newValue.filter(\.isNumber).prefix(10))
                    }

                // Pincode
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("PINCODE")
                        HStack {
                            TextField("Enter pincode", text: $pincode)
                                .keyboardType(.numberPad)
                                .font(.system(size: 15))
                                .onChange(of: pincode) { _, newValue in
                                    let digits = String(newValue.filter(\.isNumber).prefix(6))
                                    pincode = digits
                                    if digits.count == 6 { fetchCity() }
                                }

                            if isFetchingCity {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(AppTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(AppTheme.fieldBorder, lineWidth: 1)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 8) {
                        fieldLabel("CITY")
                        Text(city.isEmpty ? "Auto-fill" : city)
                            .font(.system(size: 15))
                            .foregroundStyle(city.isEmpty ? AppTheme.textMuted : AppTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(AppTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(AppTheme.fieldBorder, lineWidth: 1)
                            }
                    }
                    .frame(maxWidth: .infinity)
                }

                // State
                formField(title: "STATE", text: $state, placeholder: "Auto-filled from pincode")

                // Address Lines
                formField(title: "ADDRESS LINE 1", text: $addressLine1, placeholder: "House/Flat no, Street")
                formField(title: "ADDRESS LINE 2", text: $addressLine2, placeholder: "Area, Colony (optional)")
                formField(title: "LANDMARK", text: $landmark, placeholder: "Near... (optional)")

                // Type
                VStack(alignment: .leading, spacing: 8) {
                    fieldLabel("ADDRESS TYPE")
                    HStack(spacing: 10) {
                        typeChip("Home", value: "home", icon: "house.fill")
                        typeChip("Office", value: "office", icon: "building.2.fill")
                        typeChip("Other", value: "other", icon: "mappin")
                    }
                }

                // Save
                PrimaryActionButton(title: "Save Address", icon: "checkmark", isLoading: isSaving) {
                    saveAddress()
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(AppTheme.homeCanvas)
        .spiceNavigationBar(title: "Add Address")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                }
            }
        }
        .toast(isPresenting: $isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Form helpers

    private func formField(title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel(title)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(AppTheme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppTheme.fieldBorder, lineWidth: 1)
                }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(AppTheme.brandGreen)
                .frame(width: 3, height: 12)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .tracking(0.6)
        }
    }

    private func typeChip(_ label: String, value: String, icon: String) -> some View {
        let isSelected = addressType == value
        return Button { addressType = value } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.brandGreen : AppTheme.accentSoft)
            .clipShape(Capsule())
        }
    }

    // MARK: - Network

    private func fetchCity() {
        isFetchingCity = true
        let params: [String: Any] = ["pincode": pincode]
        let headers = UserDefaultManager.shared.authHeader
        var cancellables = Set<AnyCancellable>()

        service.cityByPincode(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { _ in isFetchingCity = false }
            receiveValue: { response in
                if response.status == true {
                    city = response.city ?? ""
                    state = response.state ?? ""
                }
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { _ = cancellables }
    }

    private func saveAddress() {
        guard !name.trim.isEmpty else { show("Please enter name"); return }
        guard phone.trim.isValidIndianMobileNumber() else { show("Enter valid phone"); return }
        guard pincode.count == 6 else { show("Enter valid pincode"); return }
        guard !addressLine1.trim.isEmpty else { show("Enter address line 1"); return }
        guard !city.trim.isEmpty else { show("City is required"); return }
        guard !state.trim.isEmpty else { show("State is required"); return }

        isSaving = true
        let params: [String: Any] = [
            "name": name.trim,
            "phone": phone.trim,
            "pincode": pincode.trim,
            "address_line_1": addressLine1.trim,
            "address_line_2": addressLine2.trim,
            "landmark": landmark.trim,
            "city": city.trim,
            "state": state.trim,
            "type": addressType
        ]
        let headers = UserDefaultManager.shared.authHeader
        var cancellables = Set<AnyCancellable>()

        service.storeAddress(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isSaving = false
                if case .failure(let error) = completion {
                    show((error as? RequestError)?.errorString ?? error.localizedDescription)
                }
            } receiveValue: { response in
                if response.status == true {
                    onSaved?()
                    dismiss()
                } else {
                    show(response.message ?? "Failed to save")
                }
            }
            .store(in: &cancellables)

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { _ = cancellables }
    }

    private func show(_ msg: String) {
        toastMessage = msg
        isShowToast = true
    }
}

#Preview {
    NavigationStack {
        AddAddressScreen()
    }
}
