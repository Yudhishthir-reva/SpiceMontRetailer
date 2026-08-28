//
//  CartScreen.swift
//  SpiceMontRetailer
//
//  Created on 23/08/26.
//

import SwiftUI
import Combine

struct CartScreen: View {
    @ObservedObject private var cartManager = CartManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showClearAlert: Bool = false
    @State private var showSchemeSheet: Bool = false
    @State private var orderPlacedSuccess: Bool = false
    @State private var isPlacingOrder: Bool = false
    @State private var placedOrderData: RetailerOrderPlaceData? = nil
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var deliveryRemark: String = ""
    @State private var selectedPaymentMode: Int = 0
    @StateObject private var audioRecorder = AudioRemarkManager.shared

    // Dynamic Schemes from API
    @State private var availableSchemes: [RetailerOfferScheme] = []
    @State private var availableSlabs: [RetailerQuantitySlab] = []
    @State private var isLoadingOffers: Bool = false

    private let defaults = UserDefaultManager.shared
    private let orderService = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var totalProductsCount: Int {
        cartManager.items.count
    }

    var totalUnitsCount: Int {
        cartManager.cartCount
    }

    var productTotal: Double {
        if let sub = Double(cartManager.subtotal), sub > 0 {
            return sub
        }
        return cartManager.items.reduce(0.0) { sum, item in
            let price = Double(item.price ?? item.perPrice ?? item.product?.price ?? "0") ?? 0.0
            return sum + (price * Double(item.quantity ?? 1))
        }
    }

    var finalAmount: Double {
        if let fin = Double(cartManager.finalAmount), fin > 0 {
            return fin
        }
        if let offer = cartManager.appliedOffer, let discount = offer.discountAmount, discount > 0 {
            return max(0.0, productTotal - discount)
        }
        return productTotal
    }

    // User address cached properties
    var userName: String {
        defaults.getUserDefaultsString(key: .userName)
    }

    var userAddress: String {
        defaults.getUserDefaultsString(key: .shopAddress)
    }

    var userPhone: String {
        let phone = defaults.getUserDefaultsString(key: .userPhone)
        if !phone.isEmpty { return phone }
        return defaults.getUserDefaultsString(key: .userMobile)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.appFont(size: 16, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .padding(4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cart & Checkout")
                            .font(.appFont(size: 17, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text("\(totalProductsCount) products · \(totalUnitsCount) units")
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Spacer()

                    if !cartManager.items.isEmpty {
                        Button(action: {
                            showClearAlert = true
                        }) {
                            Text("Clear")
                                .font(.appFont(size: 13, weight: .heavy))
                                .foregroundColor(Color.spicePrimary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                if cartManager.items.isEmpty {
                    // MARK: - Empty Cart State
                    emptyCartView
                } else {
                    // MARK: - Cart Items List & Summary
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(cartManager.items, id: \.identifier) { item in
                                cartItemCard(item)
                            }

                            // Dynamic Scheme Available Card (Rendered only if schemes exist or applied)
                            schemeAvailableCard

                            // Delivery Address Card
                            deliveryAddressCard

                            // Delivery Remark & Audio Note Card
                            deliveryRemarkCard

                            // Order Summary Card
                            orderSummaryCard

                            // Note Text
                            Text("No online payment is collected in the app. Payment and settlement are managed separately by SpiceMonk.")
                                .font(.appFont(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                                .lineSpacing(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                                .padding(.top, 2)

                            Spacer(minLength: 80)
                        }
                        .padding(16)
                    }
                }
            }

            // MARK: - Floating Bottom Checkout Bar
            if !cartManager.items.isEmpty {
                bottomCheckoutBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            cartManager.fetchCart()
            loadAvailableOffers()
        }
        .onChange(of: cartManager.items.count) { _, _ in
            loadAvailableOffers()
        }
        .sheet(isPresented: $showSchemeSheet) {
            SchemePickerSheet(
                cartTotal: productTotal,
                appliedSchemeId: cartManager.appliedOffer?.id,
                onSchemeSelected: { _ in
                    loadAvailableOffers()
                },
                onSchemeRemoved: {
                    loadAvailableOffers()
                }
            )
            .presentationDetents([.medium, .large])
            .presentationBackground(Color.white)
            .presentationDragIndicator(.visible)
        }
        .alert(isPresented: $showClearAlert) {
            Alert(
                title: Text("Clear Cart"),
                message: Text("Are you sure you want to remove all items from your cart?"),
                primaryButton: .destructive(Text("Clear")) {
                    cartManager.clearCart()
                    availableSchemes = []
                    availableSlabs = []
                },
                secondaryButton: .cancel()
            )
        }
        .fullScreenCover(isPresented: $orderPlacedSuccess) {
            NavigationStack {
                OrderSuccessScreen(
                    orderId: placedOrderData?.orderId,
                    orderNumber: placedOrderData?.orderNo ?? "",
                    totalAmount: finalAmount,
                    totalItems: totalProductsCount,
                    totalUnits: totalUnitsCount
                )
            }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Empty Cart View
    private var emptyCartView: some View {
        VStack(spacing: 16) {
            Spacer()
            SpiceEmptyStateView(
                title: "Your Cart is Empty",
                message: "Looks like you haven't added any products to your cart yet.",
                buttonTitle: "Start Shopping"
            ) {
                dismiss()
            }
            Spacer()
        }
    }

    // MARK: - Cart Item Card (with dynamic thumbnail & stepper pill)
    private func cartItemCard(_ item: CartItem) -> some View {
        let title = item.productName ?? item.product?.name ?? item.product?.title ?? "Spice Product"
        let unitText = item.variantName ?? item.product?.unit ?? "100 gms"
        let unitPriceVal = Double(item.price ?? item.perPrice ?? item.product?.price ?? "0") ?? 0.0
        let unitPriceText = String(format: "₹%.2f / unit", unitPriceVal)
        let qty = item.quantity ?? 1
        let lineTotal = unitPriceVal * Double(qty)
        let maxAvailable = item.maxStock

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Product Thumbnail
                RemoteImage(url: item.productImage ?? item.product?.image ?? item.product?.images?.first?.image, contentMode: .fit)
                    .frame(width: 54, height: 54)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
                    )

                // Title and Unit Details
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.appFont(size: 14.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                        .lineLimit(2)

                    Text("\(unitText) · \(unitPriceText)")
                        .font(.appFont(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)

                    if maxAvailable < 9999 {
                        Text("\(maxAvailable) in stock")
                            .font(.appFont(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(maxAvailable <= 5 ? Color.spiceDue : Color.spicePrimary)
                    }
                }

                Spacer()

                // Remove Button
                Button(action: {
                    if let pId = item.productId ?? item.id {
                        cartManager.setQuantity(
                            productId: pId,
                            variantId: item.variantId,
                            variantName: item.variantName,
                            quantity: 0
                        )
                    }
                }) {
                    Text("Remove")
                        .font(.appFont(size: 12, weight: .bold))
                        .foregroundColor(Color.spiceMuted)
                        .padding(.top, 2)
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.spiceDivider.opacity(0.8))

            // Bottom Row: Stepper Pill + Line Total
            HStack {
                // Green Stepper Pill
                HStack(spacing: 0) {
                    Button(action: {
                        if let pId = item.productId ?? item.id {
                            let newQty = max(0, qty - 1)
                            cartManager.setQuantity(
                                productId: pId,
                                variantId: item.variantId,
                                variantName: item.variantName,
                                quantity: newQty,
                                availableQuantity: maxAvailable
                            )
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.appFont(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)

                    Text("\(qty)")
                        .font(.appFont(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(minWidth: 32)

                    Button(action: {
                        if let pId = item.productId ?? item.id {
                            if qty >= maxAvailable {
                                toastMessage = "Sirf \(maxAvailable) units stock me available hain."
                                isShowToast = true
                                return
                            }
                            let newQty = min(maxAvailable, qty + 1)
                            cartManager.setQuantity(
                                productId: pId,
                                variantId: item.variantId,
                                variantName: item.variantName,
                                quantity: newQty,
                                availableQuantity: maxAvailable
                            )
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.appFont(size: 11, weight: .bold))
                            .foregroundColor(qty >= maxAvailable ? Color.white.opacity(0.35) : .white)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.spicePrimary)
                .cornerRadius(18)

                Spacer()

                // Line Total Price
                Text(String(format: "₹%.2f", lineTotal))
                    .font(.appFont(size: 15.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Scheme Available Card (Rendered ONLY if offers exist or applied)
    @ViewBuilder
    private var schemeAvailableCard: some View {
        if let applied = cartManager.appliedOffer {
            // State 1: Applied Scheme State (Mint Green)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Applied Scheme")
                        .font(.appFont(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "#167444"))

                    Spacer()

                    Button(action: {
                        handleRemoveOffer()
                    }) {
                        Text("Remove")
                            .font(.appFont(size: 12, weight: .bold))
                            .foregroundColor(Color.spicePrimary)
                    }
                    .buttonStyle(.plain)
                }

                Text(applied.schemeTitle ?? "Offer Applied")
                    .font(.appFont(size: 13, weight: .bold))
                    .foregroundColor(Color.spiceInk)

                if let desc = applied.discountText, !desc.isEmpty {
                    Text(desc)
                        .font(.appFont(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color(hex: "#EBF7EE"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
            )
        } else if !availableSchemes.isEmpty || !availableSlabs.isEmpty {
            // State 2: Available schemes exist from API
            let eligibleScheme = availableSchemes.first { $0.eligible == true || (productTotal >= ($0.minOrderValue ?? 0) && ($0.minOrderValue ?? 0) > 0) }
            let eligibleSlab = availableSlabs.first { $0.eligible == true || (totalUnitsCount >= ($0.minQty ?? 0) && ($0.minQty ?? 0) > 0) }

            if let scheme = eligibleScheme {
                // Eligible Scheme Card
                VStack(alignment: .leading, spacing: 6) {
                    Text("Scheme Available")
                        .font(.appFont(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "#167444"))

                    Text(scheme.title ?? "Special Offer")
                        .font(.appFont(size: 13, weight: .bold))
                        .foregroundColor(Color.spiceInk)

                    if let desc = scheme.description, !desc.isEmpty {
                        Text(desc)
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Button(action: {
                        showSchemeSheet = true
                    }) {
                        Text("Apply Scheme")
                            .font(.appFont(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#167444"))
                            .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(hex: "#EBF7EE"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
                )
            } else if let slab = eligibleSlab {
                // Eligible Quantity Slab Card
                VStack(alignment: .leading, spacing: 6) {
                    Text("Scheme Available")
                        .font(.appFont(size: 14, weight: .heavy))
                        .foregroundColor(Color(hex: "#167444"))

                    Text(slab.title ?? "Quantity Offer")
                        .font(.appFont(size: 13, weight: .bold))
                        .foregroundColor(Color.spiceInk)

                    if let desc = slab.description ?? slab.giftDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.appFont(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Button(action: {
                        showSchemeSheet = true
                    }) {
                        Text("Apply Scheme")
                            .font(.appFont(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#167444"))
                            .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(hex: "#EBF7EE"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
                )
            } else if let firstScheme = availableSchemes.first, let target = firstScheme.minOrderValue, target > 0 {
                // Locked / In-Progress Scheme
                let progress = min(1.0, productTotal / target)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Scheme Available")
                            .font(.appFont(size: 14, weight: .heavy))
                            .foregroundColor(Color(hex: "#8B5014"))

                        Spacer()

                        Text("₹\(Int(productTotal)) / ₹\(Int(target))")
                            .font(.appFont(size: 12.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color(hex: "#8B5014"))
                    }

                    // Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "#F0DFC9"))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "#8B5014"))
                                .frame(width: geo.size.width * progress, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.vertical, 2)

                    Text(firstScheme.title ?? firstScheme.description ?? "Add more items to unlock offer")
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceInk.opacity(0.85))

                    Button(action: {
                        showSchemeSheet = true
                    }) {
                        Text("View All Schemes")
                            .font(.appFont(size: 13, weight: .heavy))
                            .foregroundColor(Color(hex: "#8B5014"))
                            .padding(.top, 2)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(hex: "#FEF7EF"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#F0DFC9"), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Delivery Address Card
    private var deliveryAddressCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Delivery Address")
                .font(.appFont(size: 14.5, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            if !userName.isEmpty {
                Text(userName)
                    .font(.appFont(size: 13.5, weight: .bold))
                    .foregroundColor(Color.spiceInk)
            }

            if !userAddress.isEmpty {
                Text(userAddress)
                    .font(.appFont(size: 12, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .lineSpacing(2)
            }

            if !userPhone.isEmpty {
                Text(userPhone)
                    .font(.appFont(size: 12, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Delivery Remark & Voice Note Card
    private var deliveryRemarkCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(Color.spicePrimary)
                    .font(.appFont(size: 14, weight: .bold))
                Text("Delivery Remark / Instructions")
                    .font(.appFont(size: 14.5, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                Spacer()
            }

            // Text Remark Input
            TextField("e.g. Please deliver before 6pm", text: $deliveryRemark)
                .font(.appFont(size: 13, weight: .medium))
                .foregroundColor(Color.black)
                .tint(Color.spicePrimary)
                .padding(10)
                .background(Color(hex: "#F7F9F7"))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.spiceCardBorder, lineWidth: 1)
                )

            // Audio Voice Note Row
            HStack(spacing: 10) {
                if audioRecorder.isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.spiceDue)
                            .frame(width: 8, height: 8)
                        Text("Recording... \(audioRecorder.formattedDuration)")
                            .font(.appFont(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.spiceDue)
                        Spacer()
                        Button(action: {
                            audioRecorder.stopRecording()
                        }) {
                            Text("Done")
                                .font(.appFont(size: 11.5, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.spicePrimary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.spiceDue.opacity(0.08))
                    .cornerRadius(8)
                } else if audioRecorder.hasRecordedAudio {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform")
                            .foregroundColor(Color.spicePrimary)
                            .font(.appFont(size: 13, weight: .bold))
                        Text("Voice Note Attached")
                            .font(.appFont(size: 12, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                        Spacer()
                        Button(action: {
                            audioRecorder.clearRecording()
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(Color.spiceDue)
                                .font(.appFont(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.spicePrimaryLight)
                    .cornerRadius(8)
                } else {
                    Button(action: {
                        audioRecorder.startRecording()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill")
                                .font(.appFont(size: 12, weight: .bold))
                            Text("Add Voice Note")
                                .font(.appFont(size: 12, weight: .heavy))
                        }
                        .foregroundColor(Color.spicePrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.spicePrimaryLight)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Order Summary Card
    private var orderSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order Summary")
                .font(.appFont(size: 14.5, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            HStack {
                Text("Product Total")
                    .font(.appFont(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                Spacer()
                Text(String(format: "₹%.2f", productTotal))
                    .font(.appFont(size: 13.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }

            if let offer = cartManager.appliedOffer, let discount = offer.discountAmount, discount > 0 {
                HStack {
                    Text("Scheme Discount")
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundColor(Color.spicePrimary)
                    Spacer()
                    Text(String(format: "-₹%.2f", discount))
                        .font(.appFont(size: 13.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spicePrimary)
                }
            }

            Divider().background(Color.spiceDivider).padding(.vertical, 2)

            HStack {
                Text("Final Order Amount")
                    .font(.appFont(size: 14, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Text(String(format: "₹%.2f", finalAmount))
                    .font(.appFont(size: 15.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Sticky Bottom Checkout Bar
    private var bottomCheckoutBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.spiceDivider)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL")
                        .font(.appFont(size: 10, weight: .heavy))
                        .foregroundColor(Color.spiceMuted)
                        .tracking(0.5)

                    Text(String(format: "₹%.2f", finalAmount))
                        .font(.appFont(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }

                Spacer()

                Button(action: {
                    handlePlaceOrder()
                }) {
                    HStack(spacing: 6) {
                        if isPlacingOrder {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Place Order")
                                .font(.appFont(size: 14, weight: .heavy))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 160, height: 46)
                    .background(Color.spicePrimary)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(isPlacingOrder)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white)
        }
    }

    // MARK: - Load Available Offers from API
    private func loadAvailableOffers() {
        isLoadingOffers = true
        let headers = defaults.authHeader

        orderService.fetchAvailableOffers(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [self] _ in
                self.isLoadingOffers = false
            } receiveValue: { [self] response in
                self.availableSchemes = response.data?.schemes ?? []
                self.availableSlabs = response.data?.slabs ?? []
            }
            .store(in: &cancellables)
    }

    // MARK: - Remove Applied Offer API
    private func handleRemoveOffer() {
        let headers = defaults.authHeader
        orderService.removeOffer(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [self] response in
                cartManager.appliedOffer = nil
                toastMessage = response.message ?? "Promotion remove ho gayi"
                isShowToast = true
                loadAvailableOffers()
            }
            .store(in: &cancellables)
    }

    // MARK: - Place Order Action
    private func handlePlaceOrder() {
        guard !cartManager.items.isEmpty else { return }
        isPlacingOrder = true

        let itemsPayload: [[String: Any]] = cartManager.items.compactMap { item in
            guard let pId = item.productId ?? item.id else { return nil }
            var dict: [String: Any] = [
                "product_id": pId,
                "quantity": item.quantity ?? 1
            ]
            if let vId = item.variantId {
                dict["variant_id"] = vId
            }
            if let unit = item.variantName {
                dict["variant_name"] = unit
            }
            return dict
        }

        var params: [String: Any] = [
            "payment_mode": selectedPaymentMode,
            "items": itemsPayload,
            "subtotal": productTotal,
            "final_amount": finalAmount
        ]

        let cleanRemark = deliveryRemark.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanRemark.isEmpty {
            params["remark"] = cleanRemark
        }

        if !audioRecorder.recordedAudioBase64.isEmpty {
            params["audio_remark"] = audioRecorder.recordedAudioBase64
        }

        if let appliedOffer = cartManager.appliedOffer {
            if let offerId = appliedOffer.id {
                params["offer_id"] = offerId
            }
        }

        let headers = defaults.authHeader

        orderService.placeOrder(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isPlacingOrder = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                if response.status == true {
                    placedOrderData = response.data
                    cartManager.clearCart()
                    audioRecorder.clearRecording()
                    deliveryRemark = ""
                    orderPlacedSuccess = true
                } else {
                    toastMessage = response.message ?? "Failed to place order"
                    isShowToast = true
                }
            }
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        CartScreen()
    }
}
