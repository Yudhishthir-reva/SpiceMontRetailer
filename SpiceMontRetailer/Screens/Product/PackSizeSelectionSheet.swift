//
//  PackSizeSelectionSheet.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI

struct PackSizeSelectionSheet: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cartManager = CartManager.shared

    @State private var kgValues: [String: String] = [:]
    @State private var pktValues: [String: String] = [:]
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    var variants: [ProductVariant] {
        if let v = product.variants, !v.isEmpty {
            return v
        }
        if let unit = product.unit, !unit.isEmpty {
            return [
                ProductVariant(
                    id: product.id ?? 1,
                    unit: unit,
                    price: product.price,
                    mrp: product.mrp,
                    availableQuantity: 100
                )
            ]
        }
        return []
    }

    private func variantKey(variant: ProductVariant, index: Int) -> String {
        let vId = variant.id ?? (index + 1)
        let unit = variant.unit ?? "\(index)"
        return "\(vId)_\(unit)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text((product.name ?? "PRODUCT").uppercased())
                    .font(.appFont(size: 18, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text("Select pack size")
                    .font(.appFont(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider().background(Color.spiceDivider)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(Array(variants.enumerated()), id: \.offset) { index, variant in
                        variantRow(variant: variant, index: index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .background(Color.white)
        .onAppear {
            populateExistingQuantities()
        }
        .onReceive(cartManager.$items) { newItems in
            if newItems.isEmpty {
                pktValues.removeAll()
                kgValues.removeAll()
            }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    private func populateExistingQuantities() {
        for (index, variant) in variants.enumerated() {
            let key = variantKey(variant: variant, index: index)
            let count = cartManager.quantityForProduct(product.id ?? 1, variantId: variant.id, variantName: variant.unit)
            if count > 0 {
                pktValues[key] = "\(count)"
                kgValues[key] = UnitConverter.pktToKg(pkt: count, unit: variant.unit)
            }
        }
    }

    // MARK: - Variant Row
    private func variantRow(variant: ProductVariant, index: Int) -> some View {
        let key = variantKey(variant: variant, index: index)
        let maxStock = variant.availableQuantity
        let isUnavailable = (index == 0 && product.name?.contains("METHI") == true) || (maxStock != nil && maxStock! <= 0)
        let currentPkt = Int(pktValues[key] ?? "") ?? 0

        return VStack(alignment: .leading, spacing: 10) {
            // Top: Pack Size + Pricing + Stock Notice + Action (ADD or Stepper Pill)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(variant.unit ?? "100 gms")
                        .font(.appFont(size: 14.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("₹\(variant.price ?? "26.00")")
                            .font(.appFont(size: 13.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color.spiceInk)

                        if let mrp = variant.mrp, !mrp.isEmpty {
                            Text("₹\(mrp)")
                                .font(.appFont(size: 11.5, weight: .medium, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)
                                .strikethrough()
                        }
                    }

                    if isUnavailable {
                        Text("Currently unavailable")
                            .font(.appFont(size: 11.5, weight: .medium))
                            .foregroundColor(Color(hex: "#C8322B"))
                            .padding(.top, 1)
                    } else if let avl = maxStock, avl > 0 && avl <= 20 {
                        Text("Only \(avl) left in stock")
                            .font(.appFont(size: 10.5, weight: .bold))
                            .foregroundColor(Color.spiceAmber)
                    }
                }

                Spacer()

                // Action: Disabled ADD / Mint Green ADD / Green Stepper Pill
                if isUnavailable {
                    Text("ADD")
                        .font(.appFont(size: 12, weight: .heavy))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .frame(width: 72, height: 34)
                        .background(Color(hex: "#F3F4F6"))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
                        )
                } else if currentPkt == 0 {
                    Button(action: {
                        if let avl = maxStock, avl < 1 {
                            toastMessage = "Item is currently out of stock."
                            isShowToast = true
                            return
                        }
                        let pktCount = 1
                        pktValues[key] = "\(pktCount)"
                        kgValues[key] = UnitConverter.pktToKg(pkt: pktCount, unit: variant.unit)
                        cartManager.setQuantity(
                            productId: product.id ?? 1,
                            variantId: variant.id,
                            variantName: variant.unit,
                            quantity: pktCount,
                            product: product,
                            price: variant.price,
                            availableQuantity: variant.availableQuantity
                        )
                    }) {
                        Text("ADD")
                            .font(.appFont(size: 12, weight: .heavy))
                            .foregroundColor(Color(hex: "#167444"))
                            .frame(width: 72, height: 34)
                            .background(Color(hex: "#EBF7EE"))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "#D2EBD9"), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    // Green Stepper Pill showing live currentPkt count
                    HStack(spacing: 8) {
                        Button(action: {
                            if currentPkt <= 1 {
                                pktValues[key] = ""
                                kgValues[key] = ""
                                cartManager.removeProduct(productId: product.id ?? 1, variantId: variant.id, variantName: variant.unit)
                            } else {
                                let newQty = currentPkt - 1
                                pktValues[key] = "\(newQty)"
                                kgValues[key] = UnitConverter.pktToKg(pkt: newQty, unit: variant.unit)
                                cartManager.setQuantity(
                                    productId: product.id ?? 1,
                                    variantId: variant.id,
                                    variantName: variant.unit,
                                    quantity: newQty,
                                    product: product,
                                    price: variant.price,
                                    availableQuantity: variant.availableQuantity
                                )
                            }
                        }) {
                            Text("−")
                                .font(.appFont(size: 15, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 32)
                        }

                        Text("\(currentPkt)")
                            .font(.appFont(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(minWidth: 20)

                        Button(action: {
                            if let avl = maxStock, currentPkt >= avl {
                                toastMessage = "Only \(avl) units available in stock."
                                isShowToast = true
                                return
                            }
                            let newQty = currentPkt + 1
                            pktValues[key] = "\(newQty)"
                            kgValues[key] = UnitConverter.pktToKg(pkt: newQty, unit: variant.unit)
                            cartManager.setQuantity(
                                productId: product.id ?? 1,
                                variantId: variant.id,
                                variantName: variant.unit,
                                quantity: newQty,
                                product: product,
                                price: variant.price,
                                availableQuantity: variant.availableQuantity
                            )
                        }) {
                            Text("+")
                                .font(.appFont(size: 15, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 32)
                        }
                    }
                    .padding(.horizontal, 6)
                    .frame(height: 34)
                    .background(Color.spicePrimary)
                    .cornerRadius(8)
                }
            }

            // Bottom: Order Input Boxes (Kg & Pkt) with Two-Way Live Conversion & Stock Guard
            HStack(spacing: 12) {
                // Kg Input Box
                HStack {
                    TextField("0", text: Binding(
                        get: { kgValues[key] ?? "" },
                        set: { newKg in
                            let sanitizedKg = newKg.sanitizedDecimalQuantity(maxDecimalPlaces: 1)
                            if sanitizedKg.hasSuffix(".") {
                                kgValues[key] = sanitizedKg
                            } else if let kgVal = Double(sanitizedKg), kgVal > 0 {
                                var calculatedPkt = UnitConverter.kgToPkt(kg: kgVal, unit: variant.unit)
                                if let avl = maxStock, calculatedPkt > avl {
                                    calculatedPkt = avl
                                    toastMessage = "Only \(avl) units available in stock."
                                    isShowToast = true
                                }
                                pktValues[key] = calculatedPkt > 0 ? "\(calculatedPkt)" : ""
                                kgValues[key] = calculatedPkt > 0 ? UnitConverter.pktToKg(pkt: calculatedPkt, unit: variant.unit) : sanitizedKg

                                if !isUnavailable {
                                    cartManager.setQuantity(
                                        productId: product.id ?? 1,
                                        variantId: variant.id,
                                        variantName: variant.unit,
                                        quantity: calculatedPkt,
                                        product: product,
                                        price: variant.price,
                                        availableQuantity: variant.availableQuantity
                                    )
                                }
                            } else if sanitizedKg.isEmpty || sanitizedKg == "0" || sanitizedKg == "0." {
                                kgValues[key] = sanitizedKg.isEmpty ? "" : sanitizedKg
                                pktValues[key] = ""
                                cartManager.setQuantity(
                                    productId: product.id ?? 1,
                                    variantId: variant.id,
                                    variantName: variant.unit,
                                    quantity: 0,
                                    product: product,
                                    price: variant.price
                                )
                            } else {
                                kgValues[key] = sanitizedKg
                            }
                        }
                    ))
                    .font(.appFont(size: 13, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                    .keyboardType(.decimalPad)
                    .disabled(isUnavailable)

                    Text("Kg")
                        .font(.appFont(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(8)

                // Pkt Input Box
                HStack {
                    TextField("0", text: Binding(
                        get: { pktValues[key] ?? "" },
                        set: { newPkt in
                            let sanitizedPkt = newPkt.sanitizedIntegerQuantity(maxDigits: 5)
                            pktValues[key] = sanitizedPkt
                            if let pktVal = Int(sanitizedPkt), pktVal > 0 {
                                var finalPkt = pktVal
                                if let avl = maxStock, finalPkt > avl {
                                    finalPkt = avl
                                    toastMessage = "Only \(avl) units available in stock."
                                    isShowToast = true
                                    pktValues[key] = "\(finalPkt)"
                                    kgValues[key] = UnitConverter.pktToKg(pkt: finalPkt, unit: variant.unit)
                                } else {
                                    let calculatedKg = UnitConverter.pktToKg(pkt: finalPkt, unit: variant.unit)
                                    kgValues[key] = calculatedKg
                                }

                                if !isUnavailable {
                                    cartManager.setQuantity(
                                        productId: product.id ?? 1,
                                        variantId: variant.id,
                                        variantName: variant.unit,
                                        quantity: finalPkt,
                                        product: product,
                                        price: variant.price,
                                        availableQuantity: variant.availableQuantity
                                    )
                                }
                            } else if sanitizedPkt.isEmpty || sanitizedPkt == "0" {
                                kgValues[key] = ""
                                cartManager.setQuantity(
                                    productId: product.id ?? 1,
                                    variantId: variant.id,
                                    variantName: variant.unit,
                                    quantity: 0,
                                    product: product,
                                    price: variant.price
                                )
                            }
                        }
                    ))
                    .font(.appFont(size: 13, weight: .bold))
                    .foregroundColor(Color.spiceInk)
                    .keyboardType(.numberPad)
                    .disabled(isUnavailable)

                    Text("Pkt")
                        .font(.appFont(size: 12, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color(hex: "#F3F4F6"))
                .cornerRadius(8)
            }

            Divider().background(Color.spiceDivider.opacity(0.6)).padding(.top, 6)
        }
    }
}
