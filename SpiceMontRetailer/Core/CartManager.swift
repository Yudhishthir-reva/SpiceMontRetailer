//
//  CartManager.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine

/// Singleton cart manager shared across the whole app so every screen can read the cart count
/// and the cart screen can mutate items without re-fetching on every appearance.
final class CartManager: ObservableObject {

    static let shared = CartManager()

    @Published var items: [CartItem] = []
    @Published var subtotal: String = "0"
    @Published var discount: String = "0"
    @Published var deliveryCharge: String = "0"
    @Published var handlingCharge: String = "0"
    @Published var packingCharge: String = "0"
    @Published var total: String = "0"
    @Published var finalAmount: String = "0"
    @Published var couponCode: String = ""
    @Published var couponDiscount: String = "0"
    @Published var appliedOffer: RetailerAppliedOffer?
    @Published var isLoading = false

    var cartCount: Int { items.reduce(0) { $0 + ($1.quantity ?? 0) } }
    var itemCount: Int { items.count }

    private let networkService: NetworkServiceManagable
    private var cancellables = Set<AnyCancellable>()
    private var debounceTasks: [String: DispatchWorkItem] = [:]
    private var stockRegistry: [String: Int] = [:]

    private init(networkService: NetworkServiceManagable = NetworkServiceManager.shared) {
        self.networkService = networkService
    }

    /// Matches a CartItem against productId + optional variant fields.
    /// Handles nil variantId/variantName (simple products without variants).
    private func itemMatchesVariant(_ item: CartItem, productId: Int, variantId: Int?, variantName: String?) -> Bool {
        guard item.productId == productId else { return false }
        // Both have variantId → match on variantId
        if item.variantId != nil && variantId != nil {
            return item.variantId == variantId
        }
        // Both have variantName → match on variantName
        if item.variantName != nil && variantName != nil {
            return item.variantName?.lowercased().trimmingCharacters(in: .whitespaces) == variantName?.lowercased().trimmingCharacters(in: .whitespaces)
        }
        // Both have NO variant info → simple product, match on productId alone
        if item.variantId == nil && variantId == nil && item.variantName == nil && variantName == nil {
            return true
        }
        // Fallback: one side has variant, other doesn't → try matching what's available
        if item.variantId != nil && item.variantId == variantId { return true }
        if item.variantName != nil && variantName != nil {
            return item.variantName?.lowercased().trimmingCharacters(in: .whitespaces) == variantName?.lowercased().trimmingCharacters(in: .whitespaces)
        }
        return false
    }

    func registerStock(productId: Int, variantId: Int? = nil, variantName: String? = nil, stock: Int) {
        guard stock >= 0 else { return }
        if let vId = variantId {
            stockRegistry["\(productId)_\(vId)"] = stock
        }
        if let vName = variantName, !vName.isEmpty {
            stockRegistry["\(productId)_\(vName.lowercased().trimmingCharacters(in: .whitespaces))"] = stock
        }
        stockRegistry["\(productId)"] = stock
    }

    func getStock(productId: Int, variantId: Int? = nil, variantName: String? = nil) -> Int? {
        if let vId = variantId, let s = stockRegistry["\(productId)_\(vId)"] {
            return s
        }
        if let vName = variantName, let s = stockRegistry["\(productId)_\(vName.lowercased().trimmingCharacters(in: .whitespaces))"] {
            return s
        }
        return stockRegistry["\(productId)"]
    }

    // MARK: - Fetch

    func fetchCart() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        let publisher: AnyPublisher<CartResponse, Error> = networkService.request(
            APIRouter.cart, params: [:] as [String: Any], headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure = completion { /* silent */ }
            } receiveValue: { [weak self] response in
                self?.applyCart(response)
            }
            .store(in: &cancellables)
    }

    // MARK: - Optimistic & Direct Add / Update

    func addProduct(product: Product, variant: ProductVariant? = nil, quantity: Int = 1, completion: ((Bool) -> Void)? = nil) {
        guard let pId = product.id, pId > 0 else { return }
        let vId = variant?.id
        let unitName = variant?.unit ?? product.unit ?? "100 gms"
        let pPrice = variant?.price ?? product.price ?? "26.00"
        let avl = variant?.availableQuantity ?? product.availableQuantity
        setQuantity(productId: pId, variantId: vId, variantName: unitName, quantity: quantity, product: product, price: pPrice, availableQuantity: avl, completion: completion)
    }

    func setQuantity(
        productId: Int,
        variantId: Int? = nil,
        variantName: String? = nil,
        quantity: Int,
        product: Product? = nil,
        price: String? = nil,
        availableQuantity: Int? = nil,
        completion: ((Bool) -> Void)? = nil
    ) {
        if let avl = availableQuantity, avl >= 0 {
            registerStock(productId: productId, variantId: variantId, variantName: variantName, stock: avl)
        }
        if let p = product {
            if let pAvl = p.availableQuantity, pAvl >= 0 {
                registerStock(productId: productId, stock: pAvl)
            }
            if let variants = p.variants {
                for v in variants {
                    if let vAvl = v.availableQuantity, vAvl >= 0 {
                        registerStock(productId: productId, variantId: v.id, variantName: v.unit, stock: vAvl)
                    }
                }
            }
        }

        var resolvedMaxAvl = availableQuantity
        if resolvedMaxAvl == nil {
            if let cached = getStock(productId: productId, variantId: variantId, variantName: variantName), cached >= 0 {
                resolvedMaxAvl = cached
            } else if let existing = items.first(where: { itemMatchesVariant($0, productId: productId, variantId: variantId, variantName: variantName) }) {
                resolvedMaxAvl = existing.maxStock
            } else if let pAvl = product?.availableQuantity, pAvl >= 0 {
                resolvedMaxAvl = pAvl
            }
        }

        var finalQty = quantity
        if let maxAvl = resolvedMaxAvl, maxAvl >= 0 {
            finalQty = min(finalQty, maxAvl)
        }

        let key = "\(productId)_\(variantId ?? 0)_\(variantName ?? "")"

        if finalQty <= 0 {
            // Optimistically set to 0 locally without immediately destroying server item
            if let idx = items.firstIndex(where: { itemMatchesVariant($0, productId: productId, variantId: variantId, variantName: variantName) }) {
                items[idx].quantity = 0
                recalculateTotals()
            }

            // Debounce removal so quick backspacing/typing doesn't trigger server delete
            debounceTasks[key]?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.executeBackendRemoval(productId: productId, variantId: variantId, variantName: variantName)
                self?.items.removeAll(where: {
                    (self?.itemMatchesVariant($0, productId: productId, variantId: variantId, variantName: variantName) ?? false) &&
                    ($0.quantity ?? 0) <= 0
                })
                self?.recalculateTotals()
                self?.debounceTasks.removeValue(forKey: key)
            }
            debounceTasks[key] = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: workItem)
            completion?(true)
            return
        }

        // 1. Instant optimistic update
        if let idx = items.firstIndex(where: { itemMatchesVariant($0, productId: productId, variantId: variantId, variantName: variantName) }) {
            items[idx].quantity = finalQty
            let priceVal = Double(items[idx].price ?? items[idx].perPrice ?? price ?? "0") ?? 0
            items[idx].totalPrice = String(format: "%.2f", priceVal * Double(finalQty))
            if let avl = resolvedMaxAvl {
                items[idx].availableQuantity = avl
            }
            recalculateTotals()
        } else {
            let itemPrice = price ?? product?.price ?? "24.50"
            let priceVal = Double(itemPrice) ?? 0
            let newItem = CartItem(
                id: nil,
                productId: productId,
                productName: product?.name ?? "Product",
                productImage: product?.image,
                variantId: variantId,
                variantName: variantName,
                quantity: finalQty,
                price: itemPrice,
                perPrice: itemPrice,
                totalPrice: String(format: "%.2f", priceVal * Double(finalQty)),
                availableQuantity: resolvedMaxAvl,
                product: product
            )
            items.append(newItem)
            recalculateTotals()
        }

        // 2. Per-Item Independent Debounce (Prevents cancelling other variants!)
        debounceTasks[key]?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.executeBackendSync(productId: productId, variantId: variantId, variantName: variantName, quantity: finalQty)
            self?.debounceTasks.removeValue(forKey: key)
        }
        debounceTasks[key] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: workItem)

        completion?(true)
    }

    func removeProduct(productId: Int, variantId: Int? = nil, variantName: String? = nil, completion: ((Bool) -> Void)? = nil) {
        let key = "\(productId)_\(variantId ?? 0)_\(variantName ?? "")"
        debounceTasks[key]?.cancel()
        debounceTasks.removeValue(forKey: key)

        var removedServerId: Int? = nil
        if let idx = items.firstIndex(where: { itemMatchesVariant($0, productId: productId, variantId: variantId, variantName: variantName) }) {
            removedServerId = items[idx].id
            items.remove(at: idx)
            recalculateTotals()
        }

        if let cId = removedServerId, cId > 0 {
            removeCartItem(cartId: cId, completion: completion)
        } else {
            completion?(true)
        }
    }

    func recalculateTotals() {
        let sum = items.reduce(0.0) { running, item in
            let price = Double(item.price ?? item.perPrice ?? item.product?.price ?? "0") ?? 0.0
            return running + (price * Double(item.quantity ?? 1))
        }
        subtotal = String(format: "%.2f", sum)
        finalAmount = String(format: "%.2f", sum)
        total = String(format: "%.2f", sum)
    }

    // MARK: - Backend Execution

    private func executeBackendSync(productId: Int, variantId: Int?, variantName: String?, quantity: Int) {
        if quantity <= 0 {
            executeBackendRemoval(productId: productId, variantId: variantId, variantName: variantName)
            return
        }

        if let existing = items.first(where: {
            $0.productId == productId &&
            (($0.variantId != nil && variantId != nil && $0.variantId == variantId) ||
             ($0.variantName != nil && variantName != nil && $0.variantName == variantName) ||
             ($0.variantId == nil && variantId == nil && $0.variantName == nil && variantName == nil))
        }), let cartId = existing.id, cartId > 0 {
            updateCartItem(cartId: cartId, quantity: quantity)
            return
        }

        let vId = variantId ?? productId
        let params: [String: Any] = [
            "product_id": productId,
            "variant_id": vId,
            "quantity": quantity,
            "qty": quantity
        ]
        let headers = UserDefaultManager.shared.authHeader

        let publisher: AnyPublisher<CartResponse, Error> = networkService.request(
            APIRouter.cartAdd, params: params, headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { comp in
                if case .failure = comp { /* silent error */ }
            } receiveValue: { [weak self] response in
                self?.applyCart(response)
            }
            .store(in: &cancellables)
    }

    private func executeBackendRemoval(productId: Int, variantId: Int? = nil, variantName: String? = nil) {
        if let existing = items.first(where: {
            $0.productId == productId &&
            (($0.variantId != nil && variantId != nil && $0.variantId == variantId) ||
             ($0.variantName != nil && variantName != nil && $0.variantName == variantName) ||
             ($0.variantId == nil && variantId == nil && $0.variantName == nil && variantName == nil))
        }), let cartId = existing.id, cartId > 0 {
            removeCartItem(cartId: cartId)
            return
        }
    }

    // MARK: - Add (API)

    func addToCart(productId: Int, variantId: Int? = nil, quantity: Int = 1, completion: ((Bool) -> Void)? = nil) {
        let vId = variantId ?? productId
        let params: [String: Any] = [
            "product_id": productId,
            "variant_id": vId,
            "quantity": quantity,
            "qty": quantity
        ]
        let headers = UserDefaultManager.shared.authHeader

        let publisher: AnyPublisher<CartResponse, Error> = networkService.request(
            APIRouter.cartAdd, params: params, headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { comp in
                if case .failure = comp { completion?(false) }
            } receiveValue: { [weak self] response in
                self?.applyCart(response)
                completion?(response.status == true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Remove (API)

    func removeCartItem(cartId: Int, completion: ((Bool) -> Void)? = nil) {
        let params: [String: Any] = ["cart_id": cartId]
        let headers = UserDefaultManager.shared.authHeader

        let publisher: AnyPublisher<CartResponse, Error> = networkService.request(
            APIRouter.cartRemove, params: params, headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { comp in
                if case .failure = comp { completion?(false) }
            } receiveValue: { [weak self] response in
                self?.applyCart(response)
                completion?(response.status == true)
            }
            .store(in: &cancellables)
    }

    func removeFromCart(productId: Int, completion: ((Bool) -> Void)? = nil) {
        if let existing = items.first(where: { $0.productId == productId }), let cartId = existing.id, cartId > 0 {
            removeCartItem(cartId: cartId, completion: completion)
            return
        }

        let params: [String: Any] = ["product_id": productId, "variant_id": productId]
        let headers = UserDefaultManager.shared.authHeader

        let publisher: AnyPublisher<CartResponse, Error> = networkService.request(
            APIRouter.cartRemove, params: params, headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { comp in
                if case .failure = comp { completion?(false) }
            } receiveValue: { [weak self] response in
                self?.applyCart(response)
                completion?(response.status == true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Update Quantity (API)

    func updateCartItem(cartId: Int, quantity: Int, completion: ((Bool) -> Void)? = nil) {
        let params: [String: Any] = [
            "cart_id": cartId,
            "qty": quantity,
            "quantity": quantity
        ]
        let headers = UserDefaultManager.shared.authHeader

        let publisher: AnyPublisher<CartResponse, Error> = networkService.request(
            APIRouter.cartUpdate, params: params, headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] comp in
                if case .failure = comp {
                    // Stale cart_id recovery: If backend returned 404, re-add using product_id & variant_id
                    if let self = self, let idx = self.items.firstIndex(where: { $0.id == cartId }) {
                        self.items[idx].id = nil
                        let pId = self.items[idx].productId ?? 0
                        let vId = self.items[idx].variantId ?? pId
                        if pId > 0 {
                            self.addToCart(productId: pId, variantId: vId, quantity: quantity, completion: completion)
                            return
                        }
                    }
                    completion?(false)
                }
            } receiveValue: { [weak self] response in
                self?.applyCart(response)
                completion?(response.status == true)
            }
            .store(in: &cancellables)
    }

    func updateQuantity(productId: Int, variantId: Int? = nil, quantity: Int, completion: ((Bool) -> Void)? = nil) {
        if let existing = items.first(where: { $0.productId == productId && (variantId == nil || $0.variantId == variantId) }),
           let cartId = existing.id, cartId > 0 {
            updateCartItem(cartId: cartId, quantity: quantity, completion: completion)
            return
        }

        let vId = variantId ?? productId
        let params: [String: Any] = [
            "product_id": productId,
            "variant_id": vId,
            "quantity": quantity,
            "qty": quantity
        ]
        let headers = UserDefaultManager.shared.authHeader

        let publisher: AnyPublisher<CartResponse, Error> = networkService.request(
            APIRouter.cartAdd, params: params, headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { comp in
                if case .failure = comp { completion?(false) }
            } receiveValue: { [weak self] response in
                self?.applyCart(response)
                completion?(response.status == true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Clear Cart

    func clearCart(completion: ((Bool) -> Void)? = nil) {
        for (_, workItem) in debounceTasks {
            workItem.cancel()
        }
        debounceTasks.removeAll()

        items = []
        subtotal = "0"
        discount = "0"
        deliveryCharge = "0"
        handlingCharge = "0"
        packingCharge = "0"
        total = "0"
        finalAmount = "0"
        couponCode = ""
        couponDiscount = "0"
        appliedOffer = nil

        let headers = UserDefaultManager.shared.authHeader
        let publisher: AnyPublisher<CartActionResponse, Error> = networkService.request(
            APIRouter.cartClear, params: [:] as [String: Any], headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { comp in
                if case .failure = comp { completion?(false) }
            } receiveValue: { response in
                completion?(response.status == true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Place Order

    func placeOrder(
        addressId: Int? = nil,
        remark: String? = nil,
        paymentMode: Int = 0,
        audioRemark: String? = nil,
        completion: @escaping (Result<RetailerOrderPlaceData?, Error>) -> Void
    ) {
        let headers = UserDefaultManager.shared.authHeader
        var params: [String: Any] = [
            "payment_mode": paymentMode
        ]
        if let aId = addressId { params["address_id"] = aId }
        if let rem = remark, !rem.isEmpty { params["remark"] = rem }
        if let audio = audioRemark, !audio.isEmpty { params["audio_remark"] = audio }

        let publisher: AnyPublisher<OrderPlaceResponse, Error> = networkService.request(
            APIRouter.orderPlace, params: params, headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { comp in
                if case .failure(let error) = comp {
                    completion(.failure(error))
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.items = []
                    self?.subtotal = "0"
                    self?.finalAmount = "0"
                    self?.total = "0"
                    completion(.success(response.data))
                } else {
                    let errMsg = response.message ?? "Failed to place order"
                    completion(.failure(NSError(domain: "OrderPlace", code: 400, userInfo: [NSLocalizedDescriptionKey: errMsg])))
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Repeat Order

    func repeatOrder(
        items: [OrderItem],
        completion: @escaping (_ addedCount: Int, _ outOfStockNames: [String], _ adjustedNames: [String], _ success: Bool) -> Void
    ) {
        guard !items.isEmpty else {
            completion(0, [], [], false)
            return
        }

        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        let group = DispatchGroup()

        var outOfStockNames: [String] = []
        var adjustedNames: [String] = []

        struct PreparedRepeatItem {
            let productId: Int
            let variantId: Int?
            let variantName: String?
            let quantity: Int
            let price: String?
            let productName: String
            let productImage: String?
            let product: Product?
            let availableQuantity: Int?
        }

        var preparedItems: [PreparedRepeatItem] = []
        let lock = NSLock()

        for item in items {
            guard let pId = item.productId ?? item.id, pId > 0,
                  let reqQty = item.quantity, reqQty > 0 else {
                continue
            }

            group.enter()
            let params: [String: Any] = ["product_id": pId, "id": pId]
            let publisher: AnyPublisher<ProductDetailResponse, Error> = networkService.request(
                APIRouter.productDetail, params: params, headers: headers
            )

            publisher
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    group.leave()
                } receiveValue: { response in
                    let prod = response.product
                    let prodName = item.productName ?? prod?.name ?? "Product #\(pId)"

                    // 1. Out of stock check
                    if prod?.inStock == false {
                        lock.lock()
                        outOfStockNames.append(prodName)
                        lock.unlock()
                        return
                    }

                    // 2. Matching variant
                    var matchingVariant: ProductVariant? = nil
                    if let vId = item.variantId, let variants = prod?.variants {
                        matchingVariant = variants.first(where: { $0.id == vId })
                    }
                    if matchingVariant == nil, let vName = item.variantName ?? item.unit, let variants = prod?.variants {
                        matchingVariant = variants.first(where: { $0.unit == vName || $0.variantName == vName })
                    }

                    // 3. Stock availability
                    let availableStock = matchingVariant?.availableQuantity ?? prod?.availableQuantity
                    let priceToUse = matchingVariant?.price ?? prod?.price ?? item.price

                    var finalQty = reqQty
                    if let maxStock = availableStock {
                        if maxStock <= 0 {
                            lock.lock()
                            outOfStockNames.append(prodName)
                            lock.unlock()
                            return
                        } else if reqQty > maxStock {
                            finalQty = maxStock
                            lock.lock()
                            adjustedNames.append("\(prodName) (only \(maxStock) available)")
                            lock.unlock()
                        }
                    }

                    lock.lock()
                    preparedItems.append(PreparedRepeatItem(
                        productId: pId,
                        variantId: matchingVariant?.id ?? item.variantId,
                        variantName: matchingVariant?.unit ?? item.variantName ?? item.unit,
                        quantity: finalQty,
                        price: priceToUse,
                        productName: prodName,
                        productImage: prod?.image ?? item.productImage,
                        product: prod,
                        availableQuantity: availableStock
                    ))
                    lock.unlock()
                }
                .store(in: &cancellables)
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // If any items weren't validated due to network or endpoint error, fallback to raw order item
            for item in items {
                guard let pId = item.productId ?? item.id, pId > 0,
                      let reqQty = item.quantity, reqQty > 0 else { continue }
                let prodName = item.productName ?? "Product #\(pId)"

                let alreadyPrepared = preparedItems.contains(where: { $0.productId == pId && $0.variantId == item.variantId })
                let isOutOfStock = outOfStockNames.contains(prodName)

                if !alreadyPrepared && !isOutOfStock {
                    preparedItems.append(PreparedRepeatItem(
                        productId: pId,
                        variantId: item.variantId,
                        variantName: item.variantName ?? item.unit,
                        quantity: reqQty,
                        price: item.price,
                        productName: prodName,
                        productImage: item.productImage,
                        product: nil,
                        availableQuantity: nil
                    ))
                }
            }

            if preparedItems.isEmpty {
                self.isLoading = false
                completion(0, outOfStockNames, adjustedNames, false)
                return
            }

            // Cancel any pending debounces to prevent race conditions
            for (_, workItem) in self.debounceTasks {
                workItem.cancel()
            }
            self.debounceTasks.removeAll()

            // Optimistically update local items right away so cart has immediate content
            for prep in preparedItems {
                let unitPrice = prep.price ?? "0"
                let priceVal = Double(unitPrice) ?? 0
                let totalVal = priceVal * Double(prep.quantity)
                let totStr = String(format: "%.2f", totalVal)

                if let idx = self.items.firstIndex(where: { self.itemMatchesVariant($0, productId: prep.productId, variantId: prep.variantId, variantName: prep.variantName) }) {
                    self.items[idx].quantity = prep.quantity
                    self.items[idx].price = unitPrice
                    self.items[idx].perPrice = unitPrice
                    self.items[idx].totalPrice = totStr
                    if let avl = prep.availableQuantity { self.items[idx].availableQuantity = avl }
                    if let prod = prep.product { self.items[idx].product = prod }
                } else {
                    let newItem = CartItem(
                        id: nil,
                        productId: prep.productId,
                        productName: prep.productName,
                        productImage: prep.productImage,
                        variantId: prep.variantId,
                        variantName: prep.variantName,
                        quantity: prep.quantity,
                        price: unitPrice,
                        perPrice: unitPrice,
                        totalPrice: totStr,
                        availableQuantity: prep.availableQuantity,
                        product: prep.product
                    )
                    self.items.append(newItem)
                }
            }
            self.recalculateTotals()

            // Synchronize each item with the backend API
            let syncGroup = DispatchGroup()
            var backendSuccessCount = 0

            for prep in preparedItems {
                syncGroup.enter()
                let vId = prep.variantId ?? prep.productId
                let params: [String: Any] = [
                    "product_id": prep.productId,
                    "variant_id": vId,
                    "quantity": prep.quantity,
                    "qty": prep.quantity
                ]

                let pub: AnyPublisher<CartResponse, Error> = self.networkService.request(
                    APIRouter.cartAdd, params: params, headers: headers
                )

                pub.receive(on: DispatchQueue.main)
                    .sink { _ in
                        syncGroup.leave()
                    } receiveValue: { res in
                        if res.status == true {
                            backendSuccessCount += 1
                        }
                    }
                    .store(in: &self.cancellables)
            }

            syncGroup.notify(queue: .main) {
                // Refresh full cart response from backend
                self.fetchCart()
                self.isLoading = false
                let finalCount = backendSuccessCount > 0 ? backendSuccessCount : preparedItems.count
                completion(finalCount, outOfStockNames, adjustedNames, true)
            }
        }
    }

    // MARK: - Helpers

    private func applyCart(_ response: CartResponse) {
        if let responseItems = response.items {
            var merged = items

            for serverItem in responseItems {
                var itemToAdd = serverItem
                if let pId = serverItem.productId {
                    if let avl = serverItem.availableQuantity {
                        registerStock(productId: pId, variantId: serverItem.variantId, variantName: serverItem.variantName, stock: avl)
                    } else if let cached = getStock(productId: pId, variantId: serverItem.variantId, variantName: serverItem.variantName) {
                        itemToAdd.availableQuantity = cached
                    }
                }

                if let idx = merged.firstIndex(where: {
                    // Match by cart id
                    ($0.id != nil && serverItem.id != nil && $0.id == serverItem.id) ||
                    // Match by productId + variant
                    ($0.productId == serverItem.productId && $0.productId != nil && (
                        // Both have variantId → match on variantId
                        ($0.variantId != nil && serverItem.variantId != nil && $0.variantId == serverItem.variantId) ||
                        // Both have variantName → match on variantName
                        ($0.variantName != nil && serverItem.variantName != nil && $0.variantName?.lowercased().trimmingCharacters(in: .whitespaces) == serverItem.variantName?.lowercased().trimmingCharacters(in: .whitespaces)) ||
                        // Both have NO variant info → simple product, match on productId alone
                        ($0.variantId == nil && serverItem.variantId == nil && $0.variantName == nil && serverItem.variantName == nil) ||
                        // Local item has no id yet (optimistic) → match by productId + either variant field
                        ($0.id == nil && (
                            ($0.variantId != nil && $0.variantId == serverItem.variantId) ||
                            ($0.variantName != nil && $0.variantName?.lowercased().trimmingCharacters(in: .whitespaces) == serverItem.variantName?.lowercased().trimmingCharacters(in: .whitespaces)) ||
                            ($0.variantId == nil && $0.variantName == nil)
                        ))
                    ))
                }) {
                    merged[idx].id = serverItem.id ?? merged[idx].id
                    if let sp = serverItem.price { merged[idx].price = sp }
                    if let spp = serverItem.perPrice { merged[idx].perPrice = spp }
                    if let stp = serverItem.totalPrice { merged[idx].totalPrice = stp }
                    if let q = serverItem.quantity, q > 0 { merged[idx].quantity = q }
                    if let avl = serverItem.availableQuantity {
                        merged[idx].availableQuantity = avl
                    } else if merged[idx].availableQuantity == nil, let pId = merged[idx].productId {
                        merged[idx].availableQuantity = getStock(productId: pId, variantId: merged[idx].variantId, variantName: merged[idx].variantName)
                    }
                    if let prod = serverItem.product { merged[idx].product = prod }
                    if let vari = serverItem.variant { merged[idx].variant = vari }
                    if let name = serverItem.productName, !name.isEmpty { merged[idx].productName = name }
                    if let img = serverItem.productImage, !img.isEmpty { merged[idx].productImage = img }
                } else {
                    merged.append(itemToAdd)
                }
            }

            merged.removeAll(where: { ($0.quantity ?? 0) <= 0 })
            items = merged
        }
        recalculateTotals()
        if let st = response.subtotal, !st.isEmpty, st != "0" { subtotal = st }
        if let dis = response.discount { discount = dis }
        if let dc = response.deliveryCharge { deliveryCharge = dc }
        if let hc = response.handlingCharge { handlingCharge = hc }
        if let pc = response.packingCharge { packingCharge = pc }
        if let fa = response.finalAmount ?? response.total, !fa.isEmpty, fa != "0" { finalAmount = fa }
        if let tot = response.total, !tot.isEmpty, tot != "0" { total = tot }
        couponCode = response.couponCode ?? ""
        couponDiscount = response.couponDiscount ?? "0"
        appliedOffer = response.appliedOffer
    }

    func quantityForProduct(_ productId: Int, variantId: Int? = nil, variantName: String? = nil) -> Int {
        if variantId != nil || variantName != nil {
            if let item = items.first(where: { itemMatchesVariant($0, productId: productId, variantId: variantId, variantName: variantName) }) {
                return item.quantity ?? 0
            }
            return 0
        }
        // When variantId is nil, return total sum of ALL variants for this product
        return items
            .filter { $0.productId == productId }
            .reduce(0) { $0 + ($1.quantity ?? 0) }
    }

    func quantity(for product: Product) -> Int {
        guard let pId = product.id else { return 0 }
        return quantityForProduct(pId)
    }

    func add(product: Product, variantId: Int? = nil) {
        guard let pId = product.id, pId > 0 else { return }
        addProduct(product: product, variant: product.variants?.first(where: { $0.id == variantId }), quantity: 1)
    }

    func increment(product: Product, variantId: Int? = nil) {
        guard let pId = product.id, pId > 0 else { return }
        let current = quantityForProduct(pId, variantId: variantId)
        setQuantity(productId: pId, variantId: variantId, quantity: current + 1)
    }

    func decrement(product: Product, variantId: Int? = nil) {
        guard let pId = product.id, pId > 0 else { return }
        let current = quantityForProduct(pId, variantId: variantId)
        if current <= 1 {
            removeProduct(productId: pId, variantId: variantId)
        } else {
            setQuantity(productId: pId, variantId: variantId, quantity: current - 1)
        }
    }
}
