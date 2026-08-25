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

    private init(networkService: NetworkServiceManagable = NetworkServiceManager.shared) {
        self.networkService = networkService
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
        setQuantity(productId: pId, variantId: vId, variantName: unitName, quantity: quantity, product: product, price: pPrice, completion: completion)
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
        var finalQty = quantity
        if let maxAvl = availableQuantity, maxAvl >= 0 {
            finalQty = min(finalQty, maxAvl)
        }

        let key = "\(productId)_\(variantId ?? 0)_\(variantName ?? "")"

        if finalQty <= 0 {
            // Optimistically set to 0 locally without immediately destroying server item
            if let idx = items.firstIndex(where: {
                $0.productId == productId &&
                (($0.variantId != nil && variantId != nil && $0.variantId == variantId) ||
                 ($0.variantName != nil && variantName != nil && $0.variantName == variantName))
            }) {
                items[idx].quantity = 0
                recalculateTotals()
            }

            // Debounce removal so quick backspacing/typing doesn't trigger server delete
            debounceTasks[key]?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.executeBackendRemoval(productId: productId, variantId: variantId, variantName: variantName)
                self?.items.removeAll(where: {
                    $0.productId == productId &&
                    (($0.variantId != nil && variantId != nil && $0.variantId == variantId) ||
                     ($0.variantName != nil && variantName != nil && $0.variantName == variantName)) &&
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
        if let idx = items.firstIndex(where: {
            $0.productId == productId &&
            (($0.variantId != nil && variantId != nil && $0.variantId == variantId) ||
             ($0.variantName != nil && variantName != nil && $0.variantName == variantName))
        }) {
            items[idx].quantity = finalQty
            let priceVal = Double(items[idx].price ?? items[idx].perPrice ?? price ?? "0") ?? 0
            items[idx].totalPrice = String(format: "%.2f", priceVal * Double(finalQty))
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
        if let idx = items.firstIndex(where: {
            $0.productId == productId &&
            (($0.variantId != nil && variantId != nil && $0.variantId == variantId) ||
             ($0.variantName != nil && variantName != nil && $0.variantName == variantName))
        }) {
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
             ($0.variantName != nil && variantName != nil && $0.variantName == variantName))
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
             ($0.variantName != nil && variantName != nil && $0.variantName == variantName))
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

    func placeOrder(addressId: Int? = nil, remark: String? = nil, completion: @escaping (Result<RetailerOrderPlaceData?, Error>) -> Void) {
        let headers = UserDefaultManager.shared.authHeader
        var params: [String: Any] = [:]
        if let aId = addressId { params["address_id"] = aId }
        if let rem = remark, !rem.isEmpty { params["remark"] = rem }

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

    // MARK: - Helpers

    private func applyCart(_ response: CartResponse) {
        if let responseItems = response.items {
            var merged = items

            for serverItem in responseItems {
                if let idx = merged.firstIndex(where: {
                    ($0.id != nil && serverItem.id != nil && $0.id == serverItem.id) ||
                    ($0.productId == serverItem.productId &&
                     (($0.variantId != nil && serverItem.variantId != nil && $0.variantId == serverItem.variantId) ||
                      ($0.variantName != nil && serverItem.variantName != nil && $0.variantName?.lowercased().trimmingCharacters(in: .whitespaces) == serverItem.variantName?.lowercased().trimmingCharacters(in: .whitespaces))))
                }) {
                    merged[idx].id = serverItem.id ?? merged[idx].id
                    if let sp = serverItem.price { merged[idx].price = sp }
                    if let spp = serverItem.perPrice { merged[idx].perPrice = spp }
                    if let stp = serverItem.totalPrice { merged[idx].totalPrice = stp }
                } else {
                    merged.append(serverItem)
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
            if let item = items.first(where: {
                $0.productId == productId &&
                (($0.variantId != nil && variantId != nil && $0.variantId == variantId) ||
                 ($0.variantName != nil && variantName != nil && $0.variantName?.lowercased().trimmingCharacters(in: .whitespaces) == variantName?.lowercased().trimmingCharacters(in: .whitespaces)))
            }) {
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
