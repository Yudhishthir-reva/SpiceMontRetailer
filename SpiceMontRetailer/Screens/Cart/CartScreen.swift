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
        return productTotal
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Bar
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .padding(4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cart & Checkout")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        Text("\(totalProductsCount) products · \(totalUnitsCount) units")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                    }

                    Spacer()

                    if !cartManager.items.isEmpty {
                        Button(action: {
                            showClearAlert = true
                        }) {
                            Text("Clear")
                                .font(.system(size: 14, weight: .heavy))
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

                            // Offers Card
                            offersCard

                            // Delivery Address Card
                            deliveryAddressCard

                            // Order Summary Card
                            orderSummaryCard

                            // Note Text
                            Text("No online payment is collected in the app. Payment and settlement are managed separately by SpiceMonk.")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                                .lineSpacing(2)
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
        }
        .sheet(isPresented: $showSchemeSheet) {
            SchemePickerSheet(
                cartTotal: productTotal,
                appliedSchemeId: cartManager.appliedOffer?.id
            )
        }
        .alert(isPresented: $showClearAlert) {
            Alert(
                title: Text("Clear Cart"),
                message: Text("Are you sure you want to remove all items from your cart?"),
                primaryButton: .destructive(Text("Clear")) {
                    cartManager.clearCart()
                },
                secondaryButton: .cancel()
            )
        }
        .fullScreenCover(isPresented: $orderPlacedSuccess) {
            NavigationStack {
                OrderSuccessScreen(
                    orderId: placedOrderData?.orderId ?? 6434,
                    orderNumber: placedOrderData?.orderNo ?? "#2026-27/2968",
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

            Circle()
                .fill(Color(hex: "#F2F5F3"))
                .frame(width: 88, height: 88)
                .overlay(
                    Image(systemName: "cart")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(Color.spicePrimary)
                )

            Text("Your Cart is Empty")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            Text("Browse our products and add packs of spices to your cart.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.spiceMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                dismiss()
            }) {
                Text("Start Shopping")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color.spicePrimary)
                    .cornerRadius(10)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding(20)
    }

    // MARK: - Cart Item Card
    private func cartItemCard(_ item: CartItem) -> some View {
        let price = Double(item.price ?? item.perPrice ?? item.product?.price ?? "0") ?? 0.0
        let qty = item.quantity ?? 1
        let lineTotal = price * Double(qty)
        let name = item.productName ?? item.product?.name ?? "Product"
        let unit = item.variantName ?? item.product?.unit ?? "100 gms"
        let pId = item.productId ?? item.id ?? 1

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // Product Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#F2F4F2"))

                    if let img = item.productImage ?? item.product?.image, !img.isEmpty {
                        RemoteImage(url: img)
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .padding(2)
                    } else {
                        Image("spice_monk_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 38, height: 38)
                    }
                }
                .frame(width: 54, height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.spiceCardBorder, lineWidth: 0.8)
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                        .lineLimit(1)

                    Text("\(unit) · ₹\(String(format: "%.2f", price)) / unit")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }

                Spacer()

                Button(action: {
                    cartManager.removeProduct(productId: pId, variantId: item.variantId, variantName: item.variantName)
                }) {
                    Text("Remove")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
            }

            HStack {
                // Green Stepper Pill
                HStack(spacing: 12) {
                    Button(action: {
                        if qty <= 1 {
                            cartManager.removeProduct(productId: pId, variantId: item.variantId, variantName: item.variantName)
                        } else {
                            cartManager.setQuantity(productId: pId, variantId: item.variantId, variantName: item.variantName, quantity: qty - 1)
                        }
                    }) {
                        if qty <= 1 {
                            Image(systemName: "trash")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 28)
                        } else {
                            Text("−")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 28)
                        }
                    }

                    Text("\(qty)")
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)

                    Button(action: {
                        let maxStock = item.availableQuantity ?? item.product?.variants?.first(where: {
                            ($0.id != nil && item.variantId != nil && $0.id == item.variantId) ||
                            ($0.unit != nil && item.variantName != nil && $0.unit == item.variantName)
                        })?.availableQuantity

                        if let maxStock = maxStock, qty >= maxStock {
                            toastMessage = "Maximum available stock reached (\(maxStock) units)."
                            isShowToast = true
                        } else {
                            cartManager.setQuantity(
                                productId: pId,
                                variantId: item.variantId,
                                variantName: item.variantName,
                                quantity: qty + 1,
                                availableQuantity: maxStock
                            )
                        }
                    }) {
                        Text("+")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 28)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.spicePrimary)
                .cornerRadius(8)

                Spacer()

                Text(String(format: "₹%.2f", lineTotal))
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Offers Card
    private var offersCard: some View {
        Button(action: {
            showSchemeSheet = true
        }) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(cartManager.appliedOffer?.schemeTitle ?? "Offers & Wholesale Schemes")
                        .font(.system(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    Text(cartManager.appliedOffer?.discountText ?? "View available order schemes and quantity slabs")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(cartManager.appliedOffer != nil ? "Change" : "View All")
                        .font(.system(size: 12.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.spicePrimary)
                }
            }
            .padding(14)
            .background(Color(hex: "#F2F8F4"))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Delivery Address Card
    private var deliveryAddressCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Delivery Address")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            Text("Your registered shop address will be used for this delivery.")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(Color.spiceMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Order Summary Card
    private var orderSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order Summary")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            HStack {
                Text("Product Total")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Text(String(format: "₹%.2f", productTotal))
                    .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }

            Divider().background(Color.spiceDivider).padding(.vertical, 2)

            HStack {
                Text("Final Order Amount")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Text(String(format: "₹%.2f", finalAmount))
                    .font(.system(size: 15, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    // MARK: - Floating Bottom Checkout Bar
    private var bottomCheckoutBar: some View {
        VStack(spacing: 0) {
            Divider().background(Color.spiceDivider)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(Color.spiceMuted)
                        .tracking(0.5)

                    Text(String(format: "₹%.2f", finalAmount))
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundColor(Color.spiceInk)
                }

                Spacer()

                Button(action: {
                    isPlacingOrder = true
                    cartManager.placeOrder { result in
                        isPlacingOrder = false
                        switch result {
                        case .success(let data):
                            placedOrderData = data
                            orderPlacedSuccess = true
                        case .failure(let error):
                            toastMessage = error.localizedDescription
                            isShowToast = true
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        if isPlacingOrder {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text("Place Order")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 28)
                    .frame(height: 48)
                    .background(Color.spicePrimary)
                    .cornerRadius(10)
                }
                .disabled(isPlacingOrder)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(Color.white)
        }
    }
}
