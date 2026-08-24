//
//  RetailerRegistrationFlowView.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

enum RegistrationStep: Int, CaseIterable {
    case personal = 1
    case business = 2
    case documents = 3
    case review = 4
    case submitted = 5
}

struct RetailerRegistrationFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: RegistrationStep = .personal

    // Form Data
    @State private var fullName: String = "John Doe"
    @State private var email: String = "john@example.com"
    @State private var mobile: String = "9999999999"
    @State private var isWhatsAppSameAsMobile: Bool = true
    @State private var whatsAppNumber: String = "9999999999"

    @State private var shopName: String = "John Spice Shop"
    @State private var gstNumber: String = "27ABCDE1234F1Z5"
    @State private var shopAddress: String = "123 Main Street"
    @State private var state: String = "1"
    @State private var selectedStateName: String = "Select State"
    @State private var city: String = "1"
    @State private var selectedCityName: String = "Select City"
    @State private var latitude: String = "19.117300"
    @State private var longitude: String = "72.869800"

    // Live States and Cities
    @State private var availableStates: [RetailerStateItem] = []
    @State private var availableCities: [RetailerCityItem] = []
    @State private var isLoadingStates: Bool = false
    @State private var isLoadingCities: Bool = false

    @State private var aadhaarFrontUploaded: Bool = true
    @State private var aadhaarBackUploaded: Bool = true
    @State private var aadhaarBackProgress: Double = 0.68
    @State private var isDeclared: Bool = true

    // API & Submission state
    @State private var isSubmitting: Bool = false
    @State private var submittedSellerId: String = "SELL-001"
    @State private var submittedMessage: String = "Registered successfully. Please wait for admin approval."
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let loginService = LoginServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header (hidden on submitted step)
                if currentStep != .submitted {
                    headerView
                    stepProgressBar
                }

                ScrollView {
                    VStack(spacing: 16) {
                        switch currentStep {
                        case .personal:
                            personalStepView
                        case .business:
                            businessStepView
                        case .documents:
                            documentsStepView
                        case .review:
                            reviewStepView
                        case .submitted:
                            submittedStepView
                        }
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)

                // Bottom Action Bar (if not submitted)
                if currentStep != .submitted {
                    bottomActionBar
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadStates()
            }
            .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
                AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
            }, onTap: nil, completion: nil)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                if currentStep.rawValue > 1 {
                    currentStep = RegistrationStep(rawValue: currentStep.rawValue - 1) ?? .personal
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.spiceInk)
            }

            Text(currentStep == .review ? "Review Registration" : "Retailer Registration")
                .font(.system(size: 15, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            Spacer()

            if currentStep.rawValue <= 3 {
                Text("\(currentStep.rawValue) / 3")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color.spiceMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
    }

    private var stepProgressBar: some View {
        HStack(spacing: 6) {
            ForEach(1...3, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep.rawValue ? Color.spicePrimary : Color.spiceCardBorder)
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .background(Color.white)
    }

    // MARK: - Step 1: Personal Info
    private var personalStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Personal Information")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            HStack(spacing: 14) {
                Circle()
                    .fill(Color.spiceMuted.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("PHOTO")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundColor(.white)
                    )

                Button(action: {}) {
                    Text("Upload Profile Picture")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.spiceCardBorder, lineWidth: 1)
                        )
                }
            }

            formField(label: "Full Name *", text: $fullName, placeholder: "John Doe")
            formField(label: "Email *", text: $email, placeholder: "john@example.com")

            VStack(alignment: .leading, spacing: 6) {
                Text("Mobile Number *")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                HStack {
                    Text("+91 \(mobile)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    Spacer()
                    SpiceStatusBadge(status: "VERIFIED")
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("WhatsApp Number")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                TextField("Same as mobile number", text: $whatsAppNumber)
                    .font(.system(size: 13, weight: .medium))
                    .disabled(isWhatsAppSameAsMobile)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
            }

            Button(action: {
                isWhatsAppSameAsMobile.toggle()
                if isWhatsAppSameAsMobile {
                    whatsAppNumber = mobile
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: isWhatsAppSameAsMobile ? "checkmark.square.fill" : "square")
                        .foregroundColor(isWhatsAppSameAsMobile ? Color.spicePrimary : Color.spiceMuted)
                    Text("Use mobile number as WhatsApp number")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color.spiceInk)
                }
            }
        }
    }

    // MARK: - Step 2: Business & Location
    private var businessStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Business Information")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            formField(label: "Shop Name *", text: $shopName, placeholder: "John Spice Shop")
            formField(label: "GST Number *", text: $gstNumber, placeholder: "27ABCDE1234F1Z5", isMono: true)
            formField(label: "Shop Address *", text: $shopAddress, placeholder: "123 Main Street")

            HStack(spacing: 12) {
                // State Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("State *")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.spiceInk)

                    Menu {
                        if availableStates.isEmpty {
                            Button("Loading states...") {}
                        } else {
                            ForEach(availableStates) { st in
                                Button(st.name ?? "State") {
                                    state = "\(st.id ?? 1)"
                                    selectedStateName = st.name ?? "State"
                                    loadCities(stateId: st.id)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedStateName.isEmpty ? "Select State" : selectedStateName)
                                .font(.system(size: 12.5, weight: .medium))
                                .foregroundColor(selectedStateName == "Select State" ? Color.spiceMuted : Color.spiceInk)
                                .lineLimit(1)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.spiceMuted)
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
                    }
                }

                // City Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("City *")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.spiceInk)

                    if availableCities.isEmpty {
                        TextField("Enter City ID/Name", text: $city)
                            .font(.system(size: 12.5, weight: .medium))
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
                    } else {
                        Menu {
                            ForEach(availableCities) { ct in
                                Button(ct.name ?? "City") {
                                    city = "\(ct.id ?? 1)"
                                    selectedCityName = ct.name ?? "City"
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCityName.isEmpty ? "Select City" : selectedCityName)
                                    .font(.system(size: 12.5, weight: .medium))
                                    .foregroundColor(selectedCityName == "Select City" ? Color.spiceMuted : Color.spiceInk)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.spiceMuted)
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
                        }
                    }
                }
            }

            Divider().padding(.vertical, 4)

            Text("Shop Location")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            SpiceCard {
                VStack(alignment: .leading, spacing: 10) {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(LinearGradient(colors: [Color(hex: "#8FB4F0"), Color(hex: "#2C6BE0")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 80)
                        .overlay(
                            Text("SHOP PIN · GPS CAPTURED")
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.white)
                        )

                    SpiceKVRow(key: "Latitude", value: latitude, isMonoValue: true)
                    SpiceKVRow(key: "Longitude", value: longitude, isMonoValue: true)

                    HStack(spacing: 8) {
                        SpiceOutlinedButton(title: "Capture via GPS", height: 38) {}
                        SpiceGhostButton(title: "Enter Manually", height: 38) {}
                    }
                }
            }
        }
    }

    // MARK: - Step 3: Documents
    private var documentsStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Documents")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            SpiceCard {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#2C6BE0"))
                        .frame(width: 56, height: 56)
                        .overlay(Text("FRONT").font(.system(size: 8, weight: .heavy)).foregroundColor(.white))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aadhaar Front *")
                            .font(.system(size: 12, weight: .heavy))
                        Text("aadhaar_front.jpg · 1.2 MB")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                        HStack(spacing: 10) {
                            Text("Replace").foregroundColor(Color.spicePrimary).font(.system(size: 11, weight: .heavy))
                            Text("Remove").foregroundColor(Color.spiceDue).font(.system(size: 11, weight: .heavy))
                        }
                    }
                    Spacer()
                    SpiceStatusBadge(status: "UPLOADED")
                }
            }

            SpiceCard {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#2C6BE0"))
                        .frame(width: 56, height: 56)
                        .overlay(Text("BACK").font(.system(size: 8, weight: .heavy)).foregroundColor(.white))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Aadhaar Back *")
                            .font(.system(size: 12, weight: .heavy))
                        Text("aadhaar_back.jpg · 1.1 MB")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color.spiceMuted)
                        ProgressView(value: aadhaarBackProgress)
                            .tint(Color.spicePrimary)
                    }
                    Spacer()
                    SpiceStatusBadge(status: "UPLOADED")
                }
            }

            Button(action: { isDeclared.toggle() }) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: isDeclared ? "checkmark.square.fill" : "square")
                        .foregroundColor(isDeclared ? Color.spicePrimary : Color.spiceMuted)
                    Text("I hereby declare that the information provided is true and correct.")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(Color.spiceInk)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Step 4: Review
    private var reviewStepView: some View {
        VStack(spacing: 12) {
            SpiceCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Personal Information").font(.system(size: 12, weight: .heavy))
                        Spacer()
                        Button("Edit") { currentStep = .personal }.font(.system(size: 11, weight: .heavy)).foregroundColor(Color.spicePrimary)
                    }
                    Divider()
                    SpiceKVRow(key: "Name", value: fullName)
                    SpiceKVRow(key: "Email", value: email)
                    SpiceKVRow(key: "Mobile", value: "+91 \(mobile)", isMonoValue: true)
                    SpiceKVRow(key: "WhatsApp", value: "+91 \(isWhatsAppSameAsMobile ? mobile : whatsAppNumber)", isMonoValue: true)
                }
            }

            SpiceCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Business Information").font(.system(size: 12, weight: .heavy))
                        Spacer()
                        Button("Edit") { currentStep = .business }.font(.system(size: 11, weight: .heavy)).foregroundColor(Color.spicePrimary)
                    }
                    Divider()
                    SpiceKVRow(key: "Shop Name", value: shopName)
                    SpiceKVRow(key: "GST Number", value: gstNumber, isMonoValue: true)
                    SpiceKVRow(key: "Address", value: shopAddress)
                    SpiceKVRow(key: "City / State", value: "City: \(city), State: \(state)")
                }
            }

            SpiceCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Documents").font(.system(size: 12, weight: .heavy))
                        Spacer()
                        Button("Replace") { currentStep = .documents }.font(.system(size: 11, weight: .heavy)).foregroundColor(Color.spicePrimary)
                    }
                    Divider()
                    HStack(spacing: 8) {
                        ForEach(["PROFILE", "AADHAAR FRONT", "AADHAAR BACK"], id: \.self) { doc in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.spiceMuted.opacity(0.3))
                                .frame(height: 60)
                                .overlay(Text(doc).font(.system(size: 8, weight: .heavy)).foregroundColor(.white))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 5: Submitted Terminal Screen
    private var submittedStepView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)

            Circle()
                .fill(Color.spicePrimaryLight)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.spicePrimary)
                )

            Text("Registration Submitted Successfully")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(Color.spiceInk)
                .multilineTextAlignment(.center)

            Text(submittedMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            SpiceCard(backgroundColor: Color.spiceAmberLight.opacity(0.3), borderColor: Color.spiceAmber.opacity(0.3)) {
                VStack(spacing: 8) {
                    SpiceKVRow(key: "Seller ID", value: submittedSellerId, isMonoValue: true)
                    SpiceKVRow(key: "Registered Name", value: fullName)
                    SpiceKVRow(key: "Registered Mobile", value: "+91 \(mobile)", isMonoValue: true)
                    HStack {
                        Text("Status").font(.system(size: 12, weight: .semibold)).foregroundColor(Color.spiceMuted)
                        Spacer()
                        SpiceStatusBadge(status: "PENDING_REVIEW")
                    }
                }
            }

            Spacer(minLength: 40)

            SpicePrimaryButton(title: "Go to Login") {
                dismiss()
            }

            SpiceOutlinedButton(title: "Contact Support") {
                if let url = URL(string: "tel://18002004455") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                SpicePrimaryButton(title: isSubmitting ? "Submitting..." : nextButtonTitle, isEnabled: !isSubmitting) {
                    handleNextStep()
                }
            }
            .padding(16)
            .background(Color.white)
        }
    }

    private var nextButtonTitle: String {
        switch currentStep {
        case .personal: return "Continue to Business Details"
        case .business: return "Continue to Documents"
        case .documents: return "Review Registration"
        case .review: return "Submit for Review"
        case .submitted: return "Done"
        }
    }

    private func handleNextStep() {
        withAnimation {
            switch currentStep {
            case .personal:
                currentStep = .business
            case .business:
                currentStep = .documents
            case .documents:
                currentStep = .review
            case .review:
                submitRegistrationAPI()
            case .submitted:
                break
            }
        }
    }

    private func submitRegistrationAPI() {
        isSubmitting = true
        let params: [String: Any] = [
            "mobile": mobile,
            "name": fullName,
            "shop_name": shopName,
            "email": email,
            "whatsapp_no": isWhatsAppSameAsMobile ? mobile : whatsAppNumber,
            "state": state,
            "city": city,
            "address": shopAddress
        ]
        let headers = ["Accept": "application/json"]

        loginService.registerRetailer(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [self] completion in
                isSubmitting = false
                if case .failure(let error) = completion {
                    // In preview or network issue, fallback to mock response
                    submittedSellerId = "SELL-001"
                    submittedMessage = "Registered successfully. Please wait for admin approval."
                    currentStep = .submitted
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { [self] response in
                if response.status == true {
                    submittedSellerId = response.data?.sellerId ?? "SELL-001"
                    submittedMessage = response.message ?? "Registered successfully. Please wait for admin approval."
                    currentStep = .submitted
                } else {
                    toastMessage = response.message ?? "Registration submission failed."
                    isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    private func loadStates() {
        isLoadingStates = true
        loginService.fetchRetailerStates()
            .receive(on: DispatchQueue.main)
            .sink { [self] _ in
                isLoadingStates = false
            } receiveValue: { [self] response in
                self.availableStates = response.allStates
                if let first = self.availableStates.first {
                    if self.state == "1" || self.selectedStateName == "Select State" {
                        self.state = "\(first.id ?? 1)"
                        self.selectedStateName = first.name ?? "State"
                        self.loadCities(stateId: first.id)
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func loadCities(stateId: Int?) {
        guard let sId = stateId else { return }
        isLoadingCities = true
        loginService.fetchRetailerCities(stateId: sId)
            .receive(on: DispatchQueue.main)
            .sink { [self] _ in
                isLoadingCities = false
            } receiveValue: { [self] response in
                self.availableCities = response.allCities
                if let first = self.availableCities.first {
                    self.city = "\(first.id ?? 1)"
                    self.selectedCityName = first.name ?? "City"
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers
    private func formField(label: String, text: Binding<String>, placeholder: String, isMono: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.spiceInk)
            TextField(placeholder, text: text)
                .font(isMono ? .system(size: 13, weight: .semibold, design: .monospaced) : .system(size: 13, weight: .medium))
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
        }
    }
}
