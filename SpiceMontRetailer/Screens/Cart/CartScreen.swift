//
//  CartScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct CartScreen: View {
    @ObservedObject private var cartManager = CartManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showAddressList: Bool = false
    @State private var orderPlacedSuccess: Bool = false
    @State private var isPlacingOrder: Bool = false

    @State private var showSchemePicker: Bool = false

    // Delivery address state
    @State private var deliveryShopName: String = "ABC General Store"
    @State private var deliveryAddress: String = "Shop 14, Krishna Market, Andheri East, Mumbai, Maharashtra 400069"
    @State private var deliveryContact: String = "+91 98765 43210"

    var productTotal: Double {
        if let sub = Double(cartManager.subtotal), sub > 0 {
            return sub
        }
        return cartManager.items.reduce(0) { sum, item in
            let price = Double(item.product?.price ?? "") ?? 78.40
            return sum + (price * Double(item.quantity ?? 1))
        }
    }

    var schemeDiscount: Double {
        if let d = Double(cartManager.discount), d > 0 {
            return d
        }
        if let cd = Double(cartManager.couponDiscount), cd > 0 {
            return cd
        }
        return (cartManager.appliedOffer != nil) ? 60.00 : 0.00
    }

    var handlingCharge: Double {
        Double(cartManager.handlingCharge) ?? 0.00
    }

    var packingCharge: Double {
        Double(cartManager.packingCharge) ?? 0.00
    }

    var gstAmount: Double {
        max(0, (productTotal - schemeDiscount) * 0.05)
    }

    var finalAmount: Double {
        if let fin = Double(cartManager.finalAmount), fin > 0 {
            return fin
        }
        return max(0, productTotal - schemeDiscount + handlingCharge + packingCharge + gstAmount)
    }

    var totalUnitsCount: Int {
        cartManager.items.reduce(0) { $0 + ($1.quantity ?? 1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Cart & Checkout")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Text("\(cartManager.itemCount) products · \(totalUnitsCount) units")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            if cartManager.items.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "cart")
                        .font(.system(size: 48))
                        .foregroundColor(Color.spiceMuted.opacity(0.4))
                    Text("Your cart is empty")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Text("Add products from any brand to start an order.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    SpicePrimaryButton(title: "Place New Order", height: 42) {
                        dismiss()
                    }
                    .frame(width: 180)
                    .padding(.top, 6)
                    Spacer()
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color.spiceBackground)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Cart Items
                        ForEach(cartManager.items) { item in
                            cartItemCard(item)
                        }

                        // Schemes / Offers Card
                        if let applied = cartManager.appliedOffer {
                            SpiceCard(backgroundColor: Color.spicePrimaryLight.opacity(0.4), borderColor: Color.spicePrimaryLight) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Scheme Applied")
                                            .font(.system(size: 11.5, weight: .heavy))
                                            .foregroundColor(Color.spicePrimary)
                                        Spacer()
                                        Button(action: { showSchemePicker = true }) {
                                            Text("Change")
                                                .font(.system(size: 11.5, weight: .heavy))
                                                .foregroundColor(Color.spicePrimary)
                                        }
                                    }
                                    Text(applied.title ?? "Trade Scheme")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    if let discAmt = applied.discountAmount {
                                        Text("Discount: ₹\(String(format: "%.2f", discAmt))")
                                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                            .foregroundColor(Color.spicePrimary)
                                    }
                                }
                            }
                        } else {
                            Button(action: { showSchemePicker = true }) {
                                SpiceCard(backgroundColor: Color.spiceAmberLight.opacity(0.25), borderColor: Color.spiceAmber.opacity(0.4)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "tag.fill")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(Color.spiceAmber)
                                                Text("Apply Wholesale Scheme")
                                                    .font(.system(size: 12, weight: .heavy))
                                                    .foregroundColor(Color.spiceInk)
                                            }
                                            Text("Select from available trade schemes & discounts")
                                                .font(.system(size: 10.5, weight: .medium))
                                                .foregroundColor(Color.spiceMuted)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(Color.spiceMuted)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Delivery Address Card
                        SpiceCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Delivery Address")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                    Button("Change") {
                                        showAddressList = true
                                    }
                                    .font(.system(size: 11, weight: .heavy))
                                    .foregroundColor(Color.spicePrimary)
                                }
                                Text(deliveryShopName)
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)
                                Text(deliveryAddress)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                                    .lineSpacing(2)
                                Text(deliveryContact)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.spiceMuted)
                            }
                        }

                        // Order Summary Bill Details
                        SpiceCard {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Order Summary")
                                        .font(.system(size: 12.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                }
                                Divider().padding(.bottom, 2)
                                SpiceKVRow(key: "Product Total", value: String(format: "₹%.2f", productTotal), isMonoValue: true)
                                if schemeDiscount > 0 {
                                    SpiceKVRow(key: "Scheme Discount", value: String(format: "− ₹%.2f", schemeDiscount), isMonoValue: true, valueColor: Color.spicePrimary)
                                }
                                if handlingCharge > 0 {
                                    SpiceKVRow(key: "Handling Charge", value: String(format: "₹%.2f", handlingCharge), isMonoValue: true)
                                }
                                if packingCharge > 0 {
                                    SpiceKVRow(key: "Packing Charge", value: String(format: "₹%.2f", packingCharge), isMonoValue: true)
                                }
                                SpiceKVRow(key: "Delivery Charges", value: "FREE", isMonoValue: true, valueColor: Color.spicePrimary)
                                SpiceKVRow(key: "GST (5%)", value: String(format: "₹%.2f", gstAmount), isMonoValue: true)
                                Divider().padding(.vertical, 2)
                                HStack {
                                    Text("Final Order Amount")
                                        .font(.system(size: 13.5, weight: .heavy))
                                        .foregroundColor(Color.spiceInk)
                                    Spacer()
                                    Text(String(format: "₹%.2f", finalAmount))
                                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                                        .foregroundColor(Color.spiceInk)
                                }
                            }
                        }

                        // Payment Notice Card
                        SpiceCard(backgroundColor: Color.spiceLightGray.opacity(0.6), borderColor: Color.spiceCardBorder) {
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(Color.spiceMuted).frame(width: 5, height: 5).padding(.top, 4)
                                Text("No online payment is collected in the app. Payment and settlement are managed separately by SpiceMonk.")
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                                    .lineSpacing(2)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)

                // Bottom Checkout Bar
                VStack(spacing: 0) {
                    Divider()
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTAL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color.spiceMuted)
                            Text(String(format: "₹%.2f", finalAmount))
                                .font(.system(size: 17, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color.spiceInk)
                        }

                        SpicePrimaryButton(title: "Place Order", isEnabled: !isPlacingOrder) {
                            isPlacingOrder = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                isPlacingOrder = false
                                orderPlacedSuccess = true
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSchemePicker) {
            SchemePickerSheet(
                cartTotal: productTotal,
                appliedSchemeId: cartManager.appliedOffer?.id
            )
        }
        .sheet(isPresented: $showAddressList) {
            NavigationStack {
                AddressListScreen(isSelectMode: true) { selected in
                    deliveryShopName = selected.name ?? "Store"
                    deliveryAddress = selected.fullAddress
                    deliveryContact = selected.phone ?? ""
                }
            }
        }
        .fullScreenCover(isPresented: $orderPlacedSuccess) {
            NavigationStack {
                OrderSuccessScreen(
                    orderNumber: "#SM10248",
                    totalAmount: finalAmount,
                    totalItems: cartManager.itemCount,
                    totalUnits: totalUnitsCount
                )
            }
        }
    }

    // MARK: - Cart Item Row Card
    private func cartItemCard(_ item: CartItem) -> some View {
        let price = Double(item.product?.price ?? "") ?? 78.40
        let qty = item.quantity ?? 1
        let lineTotal = price * Double(qty)

        return SpiceCard(padding: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [Color(hex: "#2C6BE0"), Color(hex: "#123A8E")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 56, height: 56)
                    .overlay(Text("PACK").font(.system(size: 7.5, weight: .heavy)).foregroundColor(.white))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.product?.name ?? "Spice Item")
                            .font(.system(size: 12.5, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                            .lineLimit(1)

                        Spacer()

                        Button(action: {
                            cartManager.removeFromCart(productId: item.productId ?? 0)
                        }) {
                            Text("Remove")
                                .font(.system(size: 10.5, weight: .heavy))
                                .foregroundColor(Color.spiceDue)
                        }
                    }

                    Text("\(item.product?.unit ?? "100 g") · ₹\(String(format: "%.2f", price)) / unit")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.spiceMuted)

                    HStack {
                        // Stepper
                        HStack(spacing: 8) {
                            Button(action: {
                                if qty <= 1 {
                                    cartManager.removeFromCart(productId: item.productId ?? 0)
                                } else {
                                    cartManager.updateQuantity(productId: item.productId ?? 0, quantity: qty - 1)
                                }
                            }) {
                                Text("−")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Color.spicePrimary)
                                    .frame(width: 24, height: 26)
                            }

                            Text("\(qty)")
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color.spiceInk)

                            Button(action: {
                                cartManager.updateQuantity(productId: item.productId ?? 0, quantity: qty + 1)
                            }) {
                                Text("+")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Color.spicePrimary)
                                    .frame(width: 24, height: 26)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spiceCardBorder, lineWidth: 1))

                        Spacer()

                        Text(String(format: "₹%.2f", lineTotal))
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)
                    }
                }
            }
        }
    }
}

