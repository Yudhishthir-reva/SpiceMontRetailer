//
//  OrderDetailScreen.swift
//  SpiceMontRetailer
//
//  Created on 23/08/26.
//

import SwiftUI
import Combine

struct OrderDetailScreen: View {
    var orderId: Int? = nil
    var orderNumber: String? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var order: Order? = nil
    @State private var isLoading: Bool = true
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var isRepeatingOrder: Bool = false
    @State private var showCart: Bool = false
    @ObservedObject private var cartManager = CartManager.shared

    private let service = OrderServiceManager()
    private let productService = ProductServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    init(orderId: Int? = nil, orderNumber: String? = nil) {
        self.orderId = orderId
        self.orderNumber = orderNumber
    }

    init(orderId: String) {
        let clean = orderId.replacingOccurrences(of: "#", with: "")
        if let intVal = Int(clean) {
            self.orderId = intVal
            self.orderNumber = orderId
        } else if let lastPart = clean.components(separatedBy: "/").last, let intPart = Int(lastPart) {
            self.orderId = intPart
            self.orderNumber = orderId
        } else {
            self.orderId = nil
            self.orderNumber = orderId
        }
    }

    var resolvedOrderId: Int {
        if let id = orderId, id > 0 { return id }
        if let o = order, let id = o.id, id > 0 { return id }
        if let num = orderNumber {
            let clean = num.replacingOccurrences(of: "#", with: "")
            if let intVal = Int(clean) { return intVal }
        }
        return 0
    }

    var orderNumberText: String {
        if let num = order?.orderNumberFormatted, !num.isEmpty {
            return num
        }
        if let num = orderNumber, !num.isEmpty {
            return num.hasPrefix("#") ? num : "#\(num)"
        }
        if let id = orderId, id > 0 {
            return "#\(id)"
        }
        return ""
    }

    var totalProductsCount: Int {
        order?.items?.count ?? 0
    }

    var totalUnitsCount: Int {
        order?.items?.reduce(0) { $0 + ($1.quantity ?? 1) } ?? 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.spiceBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Top Navigation Bar
                HStack(alignment: .center, spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.spiceInk)
                            .padding(4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Order Details")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(Color.spiceInk)

                        if !orderNumberText.isEmpty {
                            Text(orderNumberText)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }

                    Spacer()

                    Button(action: {
                        loadOrderDetail()
                    }) {
                        Text("Refresh")
                            .font(.system(size: 13.5, weight: .heavy))
                            .foregroundColor(Color.spicePrimary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

                if isLoading && order == nil {
                    // Clean Skeleton Loading State
                    ScrollView {
                        VStack(spacing: 12) {
                            SpiceSkeletonBox(height: 100, cornerRadius: 16)
                            SpiceSkeletonBox(height: 220, cornerRadius: 16)
                            SpiceSkeletonBox(height: 120, cornerRadius: 16)
                            SpiceSkeletonBox(height: 120, cornerRadius: 16)
                        }
                        .padding(16)
                    }
                } else if let ord = order {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            // MARK: - Card 1: Order Header Info Card
                            orderHeaderCard(ord)

                            // MARK: - Card 2: Status Timeline Card
                            statusTimelineCard(ord)

                            // MARK: - Card 3: Order Items Card
                            orderItemsCard(ord)

                            // MARK: - Card 4: Bill Summary Card
                            billSummaryCard(ord)

                            // MARK: - Card 5: Payment Managed Separately Card
                            paymentManagedCard

                            Spacer(minLength: 90)
                        }
                        .padding(16)
                    }
                    .refreshable {
                        loadOrderDetail()
                    }
                } else {
                    // Clean Empty State
                    VStack {
                        Spacer()
                        SpiceEmptyStateView(
                            title: "Order Details Unavailable",
                            message: "Unable to load details for this order. Please refresh.",
                            buttonTitle: "Retry"
                        ) {
                            loadOrderDetail()
                        }
                        Spacer()
                    }
                }
            }

            // MARK: - Sticky Bottom Dual CTA Bar
            if let ord = order {
                stickyBottomBar(ord)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadOrderDetail()
        }
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    // MARK: - Card 1: Header Info Card
    private func orderHeaderCard(_ ord: Order) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(ord.orderNumberFormatted)
                    .font(.system(size: 14.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color.spiceInk)

                Spacer()

                statusBadge(ord: ord)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Order Date")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    Spacer()
                    Text(ord.displayDateOnly.isEmpty ? (ord.orderDate ?? "-") : ord.displayDateOnly)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }

                HStack {
                    Text("Total Items")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    Spacer()
                    Text("\(totalProductsCount) products · \(totalUnitsCount) units")
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }
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

    // MARK: - Status Badge
    private func statusBadge(ord: Order) -> some View {
        let label = (ord.statusText?.isEmpty == false ? ord.statusText : ord.statusLabel) ?? "PENDING"
        let clean = label.uppercased()

        let hex = ord.statusColorHex ?? (clean == "PENDING" ? "#FFA500" : (clean == "DELIVERED" ? "#167444" : "#405189"))
        let color = Color(hex: hex)

        return Text(clean)
            .font(.system(size: 10, weight: .heavy, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(color.opacity(0.12))
            .cornerRadius(5)
    }

    // MARK: - Card 2: Status Timeline Card (Dynamic from API timeline)
    private func statusTimelineCard(_ ord: Order) -> some View {
        let timeline = ord.timeline ?? []

        return VStack(alignment: .leading, spacing: 14) {
            Text("Status Timeline")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)
                .padding(.horizontal, 2)

            if timeline.isEmpty {
                defaultTimeline(ord: ord)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(timeline.enumerated()), id: \.offset) { index, item in
                        let isLast = index == timeline.count - 1
                        orderTimelineRow(item: item, isLast: isLast)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func orderTimelineRow(item: RetailerTimelineItem, isLast: Bool) -> some View {
        let isDone = item.isDone == true
        let isActive = item.isActive == true

        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                if isDone || isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#167444"))
                } else {
                    Circle()
                        .fill(Color(hex: "#E5E7EB"))
                        .frame(width: 14, height: 14)
                        .padding(.vertical, 2)
                }

                if !isLast {
                    Rectangle()
                        .fill(isDone ? Color(hex: "#167444") : Color(hex: "#E5E7EB"))
                        .frame(width: 2, height: 32)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.label ?? item.title ?? "Status")
                    .font(.system(size: 13.5, weight: isDone || isActive ? .heavy : .semibold))
                    .foregroundColor(isDone || isActive ? Color.spiceInk : Color(hex: "#9CA3AF"))

                if let date = item.date, !date.isEmpty {
                    Text(date)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }

                if isActive {
                    Text("Current status")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(Color(hex: "#167444"))
                        .padding(.top, 1)
                }
            }

            Spacer()
        }
    }

    // Default 4-step layout if timeline array is omitted by backend
    private func defaultTimeline(ord: Order) -> some View {
        let status = (ord.status ?? "pending").lowercased()
        let isAssigned = status == "assigned" || status == "out_for_delivery" || status == "delivered"
        let isPickedUp = status == "out_for_delivery" || status == "delivered"
        let isDelivered = status == "delivered"

        return VStack(alignment: .leading, spacing: 0) {
            // Step 1: Placed
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 0) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "#167444"))
                    Rectangle().fill(Color(hex: "#E5E7EB")).frame(width: 2, height: 34)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order Placed").font(.system(size: 13.5, weight: .heavy)).foregroundColor(Color.spiceInk)
                    if !ord.displayDateOnly.isEmpty { Text(ord.displayDateOnly).font(.system(size: 11.5, weight: .medium)).foregroundColor(Color.spiceMuted) }
                    if status == "pending" { Text("Current status").font(.system(size: 11.5, weight: .bold)).foregroundColor(Color(hex: "#167444")).padding(.top, 1) }
                }
                Spacer()
            }

            // Step 2: Assigned
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 0) {
                    Circle().fill(Color(hex: "#E5E7EB")).frame(width: 14, height: 14).padding(.vertical, 2)
                    Rectangle().fill(Color(hex: "#E5E7EB")).frame(width: 2, height: 26)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Assigned to Rider").font(.system(size: 13, weight: isAssigned ? .heavy : .semibold)).foregroundColor(isAssigned ? Color.spiceInk : Color(hex: "#9CA3AF"))
                }
                Spacer()
            }

            // Step 3: Picked Up
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 0) {
                    Circle().fill(Color(hex: "#E5E7EB")).frame(width: 14, height: 14).padding(.vertical, 2)
                    Rectangle().fill(Color(hex: "#E5E7EB")).frame(width: 2, height: 26)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Picked Up").font(.system(size: 13, weight: isPickedUp ? .heavy : .semibold)).foregroundColor(isPickedUp ? Color.spiceInk : Color(hex: "#9CA3AF"))
                }
                Spacer()
            }

            // Step 4: Delivered
            HStack(alignment: .top, spacing: 14) {
                Circle().fill(Color(hex: "#E5E7EB")).frame(width: 14, height: 14).padding(.vertical, 2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Delivered").font(.system(size: 13, weight: isDelivered ? .heavy : .semibold)).foregroundColor(isDelivered ? Color.spiceInk : Color(hex: "#9CA3AF"))
                }
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Card 3: Order Items Card
    private func orderItemsCard(_ ord: Order) -> some View {
        let items = ord.items ?? []

        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Order Items")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

                Text("At the prices and schemes applied when the order was placed")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
            }

            Divider().background(Color.spiceDivider).padding(.vertical, 2)

            if items.isEmpty {
                Text("No items recorded for this order.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        HStack(alignment: .center, spacing: 12) {
                            // Thumbnail
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#F4F6F4"))

                                if let img = item.productImage, !img.isEmpty {
                                    RemoteImage(url: img)
                                        .scaledToFit()
                                        .frame(width: 44, height: 44)
                                        .padding(2)
                                } else {
                                    Image("spice_monk_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 36, height: 36)
                                }
                            }
                            .frame(width: 48, height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.spiceCardBorder, lineWidth: 0.8)
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.productName ?? "Product")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundColor(Color.spiceInk)

                                let unitStr = item.unit ?? ""
                                let qtyStr = "\(item.quantity ?? 1)"
                                let priceStr = item.price?.priceLabel ?? "₹0.00"
                                Text("\(unitStr.isEmpty ? "" : "\(unitStr) · ")\(qtyStr) × \(priceStr)")
                                    .font(.system(size: 11.5, weight: .medium))
                                    .foregroundColor(Color.spiceMuted)
                            }

                            Spacer()

                            Text(item.totalPrice?.priceLabel ?? item.price?.priceLabel ?? "₹0.00")
                                .font(.system(size: 13.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color.spiceInk)
                        }
                    }
                }
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

    // MARK: - Card 4: Bill Summary Card
    private func billSummaryCard(_ ord: Order) -> some View {
        let subtotalStr = (ord.subtotal?.isEmpty == false ? ord.subtotal : ord.total)?.priceLabel ?? "₹0.00"
        let finalTotalStr = (ord.total?.isEmpty == false ? ord.total : ord.subtotal)?.priceLabel ?? "₹0.00"

        return VStack(alignment: .leading, spacing: 10) {
            Text("Bill Summary")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(Color.spiceInk)

            HStack {
                Text("Product Total")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.spiceMuted)
                Spacer()
                Text(subtotalStr)
                    .font(.system(size: 13.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.spiceInk)
            }

            // Free Gift Row (if present)
            if let gift = ord.freeGift, !gift.isEmpty {
                HStack {
                    Text("Free Gift")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                    Spacer()
                    Text(gift)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }
            }

            // Discount Row (if present)
            if let disc = ord.discount, !disc.isEmpty, Double(disc) ?? 0 > 0 {
                HStack {
                    Text("Discount")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.spicePrimary)
                    Spacer()
                    Text("-\(disc.priceLabel)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.spicePrimary)
                }
            }

            Divider().background(Color.spiceDivider).padding(.vertical, 2)

            HStack {
                Text("Final Order Amount")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(Color.spiceInk)
                Spacer()
                Text(finalTotalStr)
                    .font(.system(size: 14.5, weight: .heavy, design: .monospaced))
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

    // MARK: - Card 5: Payment Managed Separately
    private var paymentManagedCard: some View {
        NavigationLink(destination: LedgerScreen()) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Payment Managed Separately")
                        .font(.system(size: 13.5, weight: .heavy))
                        .foregroundColor(Color.spiceInk)

                    Text("This order contributes to your outstanding balance. Settlement is recorded by SpiceMonk.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.spiceMuted)
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.spiceCardBorder.opacity(0.8), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sticky Bottom Dual CTA Bar
    private func stickyBottomBar(_ ord: Order) -> some View {
        HStack(spacing: 12) {
            // Track Order CTA (Solid Green)
            NavigationLink(destination: DeliveryTrackingScreen(orderId: ord.id ?? resolvedOrderId, orderNumber: ord.orderNumberFormatted)) {
                Text("Track Order")
                    .font(.system(size: 14.5, weight: .heavy))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color.spicePrimary)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // Repeat Order CTA (Outlined Green with Loading State)
            Button(action: {
                handleRepeatOrder(ord)
            }) {
                HStack(spacing: 8) {
                    if isRepeatingOrder {
                        ProgressView()
                            .tint(Color.spicePrimary)
                            .scaleEffect(0.8)
                    }
                    Text(isRepeatingOrder ? "Checking Stock..." : "Repeat Order")
                        .font(.system(size: 14.5, weight: .heavy))
                        .foregroundColor(Color.spicePrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.spicePrimary, lineWidth: 1.2)
                )
            }
            .buttonStyle(.plain)
            .disabled(isRepeatingOrder)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(Divider().background(Color.spiceDivider), alignment: .top)
    }

    // MARK: - Repeat Order Action (Stock & Availability Verification)
    private func handleRepeatOrder(_ ord: Order) {
        guard let items = ord.items, !items.isEmpty else {
            toastMessage = "No items to repeat"
            isShowToast = true
            return
        }

        isRepeatingOrder = true
        let headers = UserDefaultManager.shared.authHeader

        let group = DispatchGroup()
        var addedItemsCount = 0
        var outOfStockNames: [String] = []
        var adjustedNames: [String] = []

        for item in items {
            guard let pId = item.productId ?? item.id, let reqQty = item.quantity, reqQty > 0 else {
                continue
            }

            group.enter()
            productService.fetchDetail(params: ["id": pId], headers: headers)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    group.leave()
                } receiveValue: { response in
                    let prod = response.product
                    let prodName = item.productName ?? prod?.name ?? "Product #\(pId)"

                    // 1. Check if product is marked out of stock
                    if prod?.inStock == false {
                        outOfStockNames.append(prodName)
                        return
                    }

                    // 2. Find matching variant if any
                    var matchingVariant: ProductVariant? = nil
                    if let vId = item.variantId, let variants = prod?.variants {
                        matchingVariant = variants.first(where: { $0.id == vId })
                    }
                    if matchingVariant == nil, let vName = item.variantName ?? item.unit, let variants = prod?.variants {
                        matchingVariant = variants.first(where: { $0.unit == vName || $0.variantName == vName })
                    }

                    // 3. Determine available stock
                    let availableStock = matchingVariant?.availableQuantity ?? prod?.availableQuantity
                    let priceToUse = matchingVariant?.price ?? prod?.price ?? item.price

                    if let maxStock = availableStock {
                        if maxStock <= 0 {
                            outOfStockNames.append(prodName)
                            return
                        } else if reqQty > maxStock {
                            // Clamp to available stock
                            cartManager.setQuantity(
                                productId: pId,
                                variantId: matchingVariant?.id ?? item.variantId,
                                variantName: matchingVariant?.unit ?? item.variantName ?? item.unit,
                                quantity: maxStock,
                                product: prod,
                                price: priceToUse,
                                availableQuantity: maxStock
                            )
                            addedItemsCount += 1
                            adjustedNames.append("\(prodName) (only \(maxStock) available)")
                            return
                        }
                    }

                    // 4. In stock with requested quantity
                    cartManager.setQuantity(
                        productId: pId,
                        variantId: matchingVariant?.id ?? item.variantId,
                        variantName: matchingVariant?.unit ?? item.variantName ?? item.unit,
                        quantity: reqQty,
                        product: prod,
                        price: priceToUse,
                        availableQuantity: availableStock
                    )
                    addedItemsCount += 1
                }
                .store(in: &cancellables)
        }

        group.notify(queue: .main) {
            self.isRepeatingOrder = false

            if addedItemsCount == 0 && !outOfStockNames.isEmpty {
                self.toastMessage = "\(outOfStockNames.joined(separator: ", ")) is out of stock"
                self.isShowToast = true
            } else if !outOfStockNames.isEmpty || !adjustedNames.isEmpty {
                var notes: [String] = []
                if !outOfStockNames.isEmpty {
                    notes.append("\(outOfStockNames.count) item(s) out of stock")
                }
                if !adjustedNames.isEmpty {
                    notes.append(adjustedNames.joined(separator: ", "))
                }
                self.toastMessage = "Added \(addedItemsCount) item(s). \(notes.joined(separator: "; "))"
                self.isShowToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    self.showCart = true
                }
            } else {
                self.toastMessage = "All items added to cart successfully!"
                self.isShowToast = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showCart = true
                }
            }
        }
    }

    // MARK: - Service Call
    private func loadOrderDetail() {
        guard resolvedOrderId > 0 else {
            isLoading = false
            return
        }
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        service.fetchOrderDetail(id: resolvedOrderId, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                if let o = response.order {
                    self.order = o
                }
            }
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        OrderDetailScreen(orderId: "1")
    }
}
