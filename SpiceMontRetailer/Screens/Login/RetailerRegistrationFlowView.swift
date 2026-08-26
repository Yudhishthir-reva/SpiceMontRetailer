//
//  RetailerRegistrationFlowView.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine
import CoreLocation
import PhotosUI

// MARK: - Location Helper
final class GPSLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var latitude: String = ""
    @Published var longitude: String = ""
    @Published var isFetching: Bool = false
    @Published var locationError: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 10
    }

    func requestLocation() {
        isFetching = true
        locationError = nil
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            isFetching = false
            locationError = "Location permission denied. Please allow location in Settings."
        @unknown default:
            manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if self.isFetching || (self.latitude.isEmpty && self.longitude.isEmpty) {
                    self.isFetching = true
                    manager.startUpdatingLocation()
                }
            case .denied, .restricted:
                if self.isFetching {
                    self.isFetching = false
                    self.locationError = "Location permission denied. Please allow location in Settings."
                }
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        manager.stopUpdatingLocation()
        DispatchQueue.main.async {
            self.isFetching = false
            self.latitude = String(format: "%.6f", loc.coordinate.latitude)
            self.longitude = String(format: "%.6f", loc.coordinate.longitude)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        manager.stopUpdatingLocation()
        DispatchQueue.main.async {
            self.isFetching = false
            if self.latitude.isEmpty || self.longitude.isEmpty {
                self.locationError = error.localizedDescription
            }
        }
    }
}

// MARK: - Steps
enum RegistrationStep: Int, CaseIterable {
    case personal = 1
    case business = 2
    case documents = 3
    case review = 4
    case submitted = 5
}

// MARK: - Registration View
struct RetailerRegistrationFlowView: View {
    var initialMobile: String = ""
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: RegistrationStep = .personal

    // Step 1: Personal Info & Profile Picture
    @State private var profilePhotoItem: PhotosPickerItem?
    @State private var profilePhotoData: Data?
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var mobile: String = ""
    @State private var isWhatsAppSameAsMobile: Bool = true
    @State private var whatsAppNumber: String = ""

    // Step 2: Business Info
    @State private var shopName: String = ""
    @State private var gstNumber: String = ""
    @State private var shopAddress: String = ""
    @State private var stateId: String = ""
    @State private var selectedStateName: String = "Select State"
    @State private var cityId: String = ""
    @State private var selectedCityName: String = "Select City"
    @State private var latitude: String = ""
    @State private var longitude: String = ""

    // Live States and Cities
    @State private var availableStates: [RetailerStateItem] = []
    @State private var availableCities: [RetailerCityItem] = []
    @State private var isLoadingStates: Bool = false
    @State private var isLoadingCities: Bool = false

    // Step 3: Documents
    @State private var aadhaarFrontItem: PhotosPickerItem?
    @State private var aadhaarFrontData: Data?
    @State private var aadhaarBackItem: PhotosPickerItem?
    @State private var aadhaarBackData: Data?
    @State private var isDeclared: Bool = false

    // GPS Manager
    @StateObject private var gpsManager = GPSLocationManager()

    // API & Submission state
    @State private var isSubmitting: Bool = false
    @State private var submittedSellerId: String = ""
    @State private var submittedMessage: String = "Registration submitted successfully. Please wait for admin approval."
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
                if !initialMobile.isEmpty && mobile.isEmpty {
                    mobile = initialMobile
                }
                loadStates()
                gpsManager.requestLocation()
            }
            .onChange(of: gpsManager.latitude) { _, newLat in
                if !newLat.isEmpty {
                    latitude = newLat
                    longitude = gpsManager.longitude
                    showToast("Shop GPS location captured!")
                }
            }
            .onChange(of: gpsManager.longitude) { _, newLng in
                if !newLng.isEmpty {
                    longitude = newLng
                }
            }
            .onChange(of: gpsManager.locationError) { _, err in
                if let err = err {
                    showToast(err)
                }
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

            // Profile Picture Uploader
            profileAvatarPicker

            formField(label: "Full Name *", text: $fullName, placeholder: "e.g. Ramesh Kumar")

            formField(label: "Email Address (Optional)", text: $email, placeholder: "e.g. ramesh@example.com", keyboardType: .emailAddress)

            formField(label: "Mobile Number *", text: $mobile, placeholder: "10-digit mobile number", keyboardType: .numberPad, isMono: true)

            Toggle(isOn: $isWhatsAppSameAsMobile) {
                Text("WhatsApp number is same as mobile")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(Color.spiceInk)
            }
            .tint(Color.spicePrimary)
            .padding(.top, 4)

            if !isWhatsAppSameAsMobile {
                formField(label: "WhatsApp Number *", text: $whatsAppNumber, placeholder: "10-digit WhatsApp number", keyboardType: .numberPad, isMono: true)
            }
        }
    }

    // MARK: - Profile Avatar Picker
    private var profileAvatarPicker: some View {
        VStack(spacing: 8) {
            PhotosPicker(selection: $profilePhotoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let photoData = profilePhotoData, let uiImg = UIImage(data: photoData) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 86, height: 86)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.spicePrimary, lineWidth: 2.5))
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    } else {
                        Circle()
                            .fill(Color(hex: "#EBF7EE"))
                            .frame(width: 86, height: 86)
                            .overlay(
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .font(.system(size: 38))
                                    .foregroundColor(Color.spicePrimary)
                            )
                            .overlay(Circle().stroke(Color.spiceCardBorder, lineWidth: 1.5))
                    }

                    // Camera Action Badge
                    Circle()
                        .fill(Color.spicePrimary)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 2, y: 2)
                }
            }
            .onChange(of: profilePhotoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        DispatchQueue.main.async {
                            self.profilePhotoData = data
                        }
                    }
                }
            }

            if profilePhotoData != nil {
                HStack(spacing: 12) {
                    PhotosPicker(selection: $profilePhotoItem, matching: .images) {
                        Text("Change Photo")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color.spicePrimary)
                    }
                    Text("·").foregroundColor(Color.spiceMuted)
                    Button(action: {
                        profilePhotoData = nil
                        profilePhotoItem = nil
                    }) {
                        Text("Remove")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(Color.spiceDue)
                    }
                }
            } else {
                Text("Tap to upload profile photo (Optional)")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Step 2: Business Info
    private var businessStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Business Information")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            formField(label: "Shop Name *", text: $shopName, placeholder: "e.g. Shri Ganesh Kirana Store")

            formField(label: "GST Number (Optional)", text: $gstNumber, placeholder: "15-digit GSTIN (e.g. 27ABCDE1234F1Z5)", isMono: true)

            formField(label: "Shop Address *", text: $shopAddress, placeholder: "Shop No, Street, Landmark, Area")

            // State & City Dropdowns
            HStack(spacing: 12) {
                // State Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("State *")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.spiceInk)

                    Menu {
                        if isLoadingStates {
                            Text("Loading States...")
                        } else if availableStates.isEmpty {
                            Text("No States Available")
                        } else {
                            ForEach(availableStates) { st in
                                Button(st.name ?? "State") {
                                    stateId = "\(st.id ?? 1)"
                                    selectedStateName = st.name ?? "State"
                                    cityId = ""
                                    selectedCityName = "Select City"
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

                    Menu {
                        if isLoadingCities {
                            Text("Loading Cities...")
                        } else if availableCities.isEmpty {
                            Text("Select State first")
                        } else {
                            ForEach(availableCities) { ct in
                                Button(ct.name ?? "City") {
                                    cityId = "\(ct.id ?? 1)"
                                    selectedCityName = ct.name ?? "City"
                                }
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

            Divider().padding(.vertical, 4)

            Text("Shop GPS Location (Optional)")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            SpiceCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(Color.spicePrimary)
                        Text("Live GPS Location")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Spacer()
                        if !latitude.isEmpty && !longitude.isEmpty {
                            SpiceStatusBadge(status: "CAPTURED")
                        }
                    }

                    if !latitude.isEmpty && !longitude.isEmpty {
                        SpiceKVRow(key: "Latitude", value: latitude, isMonoValue: true)
                        SpiceKVRow(key: "Longitude", value: longitude, isMonoValue: true)
                    } else {
                        Text("Capture your shop's GPS coordinates for faster order delivery dispatch.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    HStack(spacing: 8) {
                        Button(action: {
                            gpsManager.requestLocation()
                        }) {
                            HStack(spacing: 6) {
                                if gpsManager.isFetching {
                                    ProgressView().tint(.white).scaleEffect(0.8)
                                } else {
                                    Image(systemName: "location.circle.fill")
                                }
                                Text(gpsManager.isFetching ? "Locating..." : (latitude.isEmpty ? "Capture via GPS" : "Re-Capture GPS"))
                            }
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Color.spicePrimary)
                            .cornerRadius(8)
                        }
                        .disabled(gpsManager.isFetching)
                    }
                }
            }
        }
    }

    // MARK: - Step 3: Documents
    private var documentsStepView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("KYC Documents")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            Text("Upload clear photos of your identity proof (Optional, speeds up verification)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.spiceMuted)

            // Profile Picture Card (if uploaded in Step 1 or to upload here)
            SpiceCard {
                HStack(spacing: 12) {
                    if let photoData = profilePhotoData, let uiImg = UIImage(data: photoData) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(hex: "#EBF7EE"))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "person.crop.circle")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color.spicePrimary)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile Photo")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        if let photoData = profilePhotoData {
                            Text("\(Double(photoData.count) / 1024.0 / 1024.0, specifier: "%.1f") MB · Selected")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)

                            Button(action: {
                                profilePhotoData = nil
                                profilePhotoItem = nil
                            }) {
                                Text("Remove")
                                    .foregroundColor(Color.spiceDue)
                                    .font(.system(size: 11, weight: .heavy))
                            }
                        } else {
                            PhotosPicker(selection: $profilePhotoItem, matching: .images) {
                                Text("Upload Photo")
                                    .foregroundColor(Color.spicePrimary)
                                    .font(.system(size: 11, weight: .heavy))
                            }
                        }
                    }
                    Spacer()
                    if profilePhotoData != nil {
                        SpiceStatusBadge(status: "SELECTED")
                    }
                }
            }

            // Aadhaar Front Card
            SpiceCard {
                HStack(spacing: 12) {
                    if let frontData = aadhaarFrontData, let uiImg = UIImage(data: frontData) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#EBF3FE"))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "doc.text.image")
                                    .foregroundColor(Color(hex: "#2C6BE0"))
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aadhaar / ID Front")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        if let frontData = aadhaarFrontData {
                            Text("\(Double(frontData.count) / 1024.0 / 1024.0, specifier: "%.1f") MB · Selected")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)

                            Button(action: {
                                aadhaarFrontData = nil
                                aadhaarFrontItem = nil
                            }) {
                                Text("Remove")
                                    .foregroundColor(Color.spiceDue)
                                    .font(.system(size: 11, weight: .heavy))
                            }
                        } else {
                            PhotosPicker(selection: $aadhaarFrontItem, matching: .images) {
                                Text("Upload Photo")
                                    .foregroundColor(Color.spicePrimary)
                                    .font(.system(size: 11, weight: .heavy))
                            }
                        }
                    }
                    Spacer()
                    if aadhaarFrontData != nil {
                        SpiceStatusBadge(status: "SELECTED")
                    }
                }
            }
            .onChange(of: aadhaarFrontItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        DispatchQueue.main.async {
                            self.aadhaarFrontData = data
                        }
                    }
                }
            }

            // Aadhaar Back Card
            SpiceCard {
                HStack(spacing: 12) {
                    if let backData = aadhaarBackData, let uiImg = UIImage(data: backData) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#EBF3FE"))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Image(systemName: "doc.text.image")
                                    .foregroundColor(Color(hex: "#2C6BE0"))
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Aadhaar / ID Back")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        if let backData = aadhaarBackData {
                            Text("\(Double(backData.count) / 1024.0 / 1024.0, specifier: "%.1f") MB · Selected")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)

                            Button(action: {
                                aadhaarBackData = nil
                                aadhaarBackItem = nil
                            }) {
                                Text("Remove")
                                    .foregroundColor(Color.spiceDue)
                                    .font(.system(size: 11, weight: .heavy))
                            }
                        } else {
                            PhotosPicker(selection: $aadhaarBackItem, matching: .images) {
                                Text("Upload Photo")
                                    .foregroundColor(Color.spicePrimary)
                                    .font(.system(size: 11, weight: .heavy))
                            }
                        }
                    }
                    Spacer()
                    if aadhaarBackData != nil {
                        SpiceStatusBadge(status: "SELECTED")
                    }
                }
            }
            .onChange(of: aadhaarBackItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        DispatchQueue.main.async {
                            self.aadhaarBackData = data
                        }
                    }
                }
            }

            // Declaration Checkbox
            Button(action: { isDeclared.toggle() }) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: isDeclared ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18))
                        .foregroundColor(isDeclared ? Color.spicePrimary : Color.spiceMuted)
                    Text("I hereby declare that I am an authorized retailer and the information provided above is true and correct.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceInk)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Step 4: Review
    private var reviewStepView: some View {
        VStack(spacing: 14) {
            SpiceCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Personal Information").font(.system(size: 13, weight: .heavy))
                        Spacer()
                        Button("Edit") { currentStep = .personal }
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                    }
                    Divider()

                    if let photoData = profilePhotoData, let uiImg = UIImage(data: photoData) {
                        HStack(spacing: 12) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.spicePrimary, lineWidth: 1.5))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(fullName)
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)
                                Text("+91 \(mobile)")
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundColor(Color.spiceMuted)
                            }
                        }
                        .padding(.vertical, 2)
                        Divider()
                    } else {
                        SpiceKVRow(key: "Full Name", value: fullName)
                        SpiceKVRow(key: "Mobile Number", value: "+91 \(mobile)", isMonoValue: true)
                    }

                    if !email.isEmpty {
                        SpiceKVRow(key: "Email", value: email)
                    }
                    SpiceKVRow(key: "WhatsApp", value: "+91 \(isWhatsAppSameAsMobile ? mobile : whatsAppNumber)", isMonoValue: true)
                }
            }

            SpiceCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Business Information").font(.system(size: 13, weight: .heavy))
                        Spacer()
                        Button("Edit") { currentStep = .business }
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                    }
                    Divider()
                    SpiceKVRow(key: "Shop Name", value: shopName)
                    if !gstNumber.isEmpty {
                        SpiceKVRow(key: "GSTIN", value: gstNumber, isMonoValue: true)
                    }
                    SpiceKVRow(key: "Address", value: shopAddress)
                    SpiceKVRow(key: "State", value: selectedStateName)
                    SpiceKVRow(key: "City", value: selectedCityName)
                    if !latitude.isEmpty && !longitude.isEmpty {
                        SpiceKVRow(key: "GPS Coordinates", value: "\(latitude), \(longitude)", isMonoValue: true)
                    }
                }
            }

            SpiceCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Verification Documents").font(.system(size: 13, weight: .heavy))
                        Spacer()
                        Button("Edit") { currentStep = .documents }
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                    }
                    Divider()
                    SpiceKVRow(key: "Profile Photo", value: profilePhotoData != nil ? "Attached" : "Not Provided")
                    SpiceKVRow(key: "Aadhaar Front", value: aadhaarFrontData != nil ? "Attached" : "Not Provided")
                    SpiceKVRow(key: "Aadhaar Back", value: aadhaarBackData != nil ? "Attached" : "Not Provided")
                    SpiceKVRow(key: "Declaration", value: isDeclared ? "Agreed" : "Pending")
                }
            }
        }
    }

    // MARK: - Step 5: Submitted Screen
    private var submittedStepView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 30)

            ZStack {
                Circle()
                    .fill(Color(hex: "#EBF7EE"))
                    .frame(width: 84, height: 84)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color.spicePrimary)
            }

            VStack(spacing: 6) {
                Text("Registration Submitted!")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text(submittedMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            SpiceCard {
                VStack(alignment: .leading, spacing: 8) {
                    if !submittedSellerId.isEmpty {
                        SpiceKVRow(key: "Application Ref ID", value: submittedSellerId, isMonoValue: true)
                    }
                    SpiceKVRow(key: "Applicant Name", value: fullName)
                    SpiceKVRow(key: "Shop Name", value: shopName)
                    SpiceKVRow(key: "Registered Mobile", value: "+91 \(mobile)", isMonoValue: true)
                    SpiceKVRow(key: "Status", value: "PENDING_APPROVAL")
                }
            }

            Spacer().frame(height: 16)

            SpicePrimaryButton(title: "Back to Login", height: 48) {
                dismiss()
            }
        }
    }

    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 12) {
                if currentStep.rawValue > 1 {
                    SpiceOutlinedButton(title: "Back", height: 44) {
                        currentStep = RegistrationStep(rawValue: currentStep.rawValue - 1) ?? .personal
                    }
                    .frame(width: 100)
                }

                SpicePrimaryButton(
                    title: currentStep == .review ? (isSubmitting ? "Submitting..." : "Submit Registration") : "Continue",
                    height: 44
                ) {
                    handleStepForward()
                }
                .disabled(isSubmitting)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color.white)
    }

    // MARK: - Form Validation & Navigation
    private func handleStepForward() {
        switch currentStep {
        case .personal:
            let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanMobile = mobile.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanName.isEmpty {
                showToast("Please enter your full name.")
                return
            }
            if cleanMobile.count < 10 {
                showToast("Please enter a valid 10-digit mobile number.")
                return
            }
            if !isWhatsAppSameAsMobile {
                let cleanWA = whatsAppNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanWA.count < 10 {
                    showToast("Please enter a valid 10-digit WhatsApp number.")
                    return
                }
            }
            currentStep = .business

        case .business:
            let cleanShop = shopName.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanAddress = shopAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanShop.isEmpty {
                showToast("Please enter your shop name.")
                return
            }
            if cleanAddress.isEmpty {
                showToast("Please enter your shop address.")
                return
            }
            if stateId.isEmpty || selectedStateName == "Select State" {
                showToast("Please select your state.")
                return
            }
            if cityId.isEmpty || selectedCityName == "Select City" {
                showToast("Please select your city.")
                return
            }
            currentStep = .documents

        case .documents:
            if !isDeclared {
                showToast("Please agree to the declaration to proceed.")
                return
            }
            currentStep = .review

        case .review:
            submitRegistrationAPI()

        case .submitted:
            break
        }
    }

    private func showToast(_ msg: String) {
        toastMessage = msg
        isShowToast = true
    }

    // MARK: - API Submission
    private func submitRegistrationAPI() {
        isSubmitting = true
        var params: [String: Any] = [
            "mobile": mobile.trimmingCharacters(in: .whitespacesAndNewlines),
            "name": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "shop_name": shopName.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "whatsapp_no": isWhatsAppSameAsMobile ? mobile.trimmingCharacters(in: .whitespacesAndNewlines) : whatsAppNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            "state": stateId,
            "city": cityId,
            "address": shopAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        if !gstNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            params["gstin"] = gstNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            params["gst_number"] = gstNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Latitude & Longitude
        let finalLat = !latitude.isEmpty ? latitude : gpsManager.latitude
        let finalLng = !longitude.isEmpty ? longitude : gpsManager.longitude
        if !finalLat.isEmpty { params["latitude"] = finalLat }
        if !finalLng.isEmpty { params["longitude"] = finalLng }

        let headers = ["Accept": "application/json"]

        loginService.registerRetailer(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [self] completion in
                isSubmitting = false
                if case .failure(let error) = completion {
                    let errMsg = (error as? RequestError)?.errorString ?? error.localizedDescription
                    showToast(errMsg)
                }
            } receiveValue: { [self] response in
                if response.status == true {
                    submittedSellerId = response.data?.sellerId ?? ""
                    submittedMessage = response.message ?? "Registration submitted successfully. Please wait for admin approval."
                    currentStep = .submitted
                } else {
                    showToast(response.message ?? "Registration submission failed.")
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
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers
    private func formField(
        label: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        isMono: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.spiceInk)
            TextField(placeholder, text: text)
                .font(isMono ? .system(size: 13, weight: .semibold, design: .monospaced) : .system(size: 13, weight: .medium))
                .foregroundColor(Color.black)
                .tint(Color.spicePrimary)
                .keyboardType(keyboardType)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))
        }
    }
}
