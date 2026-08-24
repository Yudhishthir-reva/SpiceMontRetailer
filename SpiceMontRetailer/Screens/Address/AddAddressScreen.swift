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
    @State private var addressType = "shop"
    @State private var isSaving = false
    @State private var isFetchingCity = false
    @State private var isShowToast = false
    @State private var toastMessage = ""
    @Environment(\.dismiss) private var dismiss

    private let service = AddressServiceManager()

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            SpiceTopBar(
                title: "Add Delivery Address",
                showBack: true,
                onBack: { dismiss() }
            )

            ScrollView {
                VStack(spacing: 14) {
                    // Contact & Shop Info Card
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Shop & Contact Details")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color.spiceInk)

                            Divider()

                            formField(title: "SHOP / OUTLET NAME", text: $name, placeholder: "e.g. ABC General Store")

                            formField(title: "CONTACT MOBILE", text: $phone, placeholder: "10-digit mobile number", keyboard: .numberPad)
                                .onChange(of: phone) { _, newValue in
                                    phone = String(newValue.filter(\.isNumber).prefix(10))
                                }
                        }
                    }

                    // Location & Pincode Card
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Delivery Location")
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundColor(Color.spiceInk)

                            Divider()

                            // Pincode & City
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 6) {
                                    fieldLabel("PINCODE")
                                    HStack {
                                        TextField("6-digit PIN", text: $pincode)
                                            .keyboardType(.numberPad)
                                            .font(.system(size: 13.5, weight: .semibold, design: .monospaced))
                                            .onChange(of: pincode) { _, newValue in
                                                let digits = String(newValue.filter(\.isNumber).prefix(6))
                                                pincode = digits
                                                if digits.count == 6 { fetchCity() }
                                            }

                                        if isFetchingCity {
                                            ProgressView().scaleEffect(0.7)
                                        }
                                    }
                                    .padding(10)
                                    .frame(height: 44)
                                    .background(Color.spiceBackground)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    fieldLabel("CITY")
                                    TextField("City", text: $city)
                                        .font(.system(size: 13.5, weight: .semibold))
                                        .padding(10)
                                        .frame(height: 44)
                                        .background(Color.spiceBackground)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))
                                }
                            }

                            // State
                            formField(title: "STATE", text: $state, placeholder: "State name")

                            // Address Lines
                            formField(title: "ADDRESS LINE 1", text: $addressLine1, placeholder: "Shop No., Building, Street Name")
                            formField(title: "ADDRESS LINE 2 (OPTIONAL)", text: $addressLine2, placeholder: "Area, Colony, Market Name")
                            formField(title: "LANDMARK (OPTIONAL)", text: $landmark, placeholder: "Near...")
                        }
                    }

                    // Address Type Card
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            fieldLabel("ADDRESS TYPE")

                            HStack(spacing: 8) {
                                typeChip("Shop / Store", value: "shop", icon: "storefront.fill")
                                typeChip("Godown / Warehouse", value: "warehouse", icon: "building.2.fill")
                                typeChip("Office", value: "office", icon: "briefcase.fill")
                            }
                        }
                    }

                    // Save Button
                    SpicePrimaryButton(title: "Save Delivery Address", height: 48, isEnabled: !isSaving) {
                        saveAddress()
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 30)
                }
                .padding(16)
            }
            .background(Color.spiceBackground)
        }
        .navigationBarHidden(true)
        .toast(isPresenting: $isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Form helpers
    private func formField(title: String, text: Binding<String>, placeholder: String, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel(title)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .font(.system(size: 13, weight: .medium))
                .padding(10)
                .frame(height: 44)
                .background(Color.spiceBackground)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Color.spiceMuted)
            .tracking(0.4)
    }

    private func typeChip(_ label: String, value: String, icon: String) -> some View {
        let isSelected = addressType == value
        return Button(action: { addressType = value }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11.5, weight: .bold))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? Color.spicePrimary : Color.white)
            .foregroundColor(isSelected ? .white : Color.spiceInk)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1))
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
        guard !name.trim.isEmpty else { show("Please enter shop/contact name"); return }
        guard phone.trim.isValidIndianMobileNumber() else { show("Enter valid 10-digit mobile"); return }
        guard pincode.count == 6 else { show("Enter valid 6-digit pincode"); return }
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
                    show(response.message ?? "Failed to save address")
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
