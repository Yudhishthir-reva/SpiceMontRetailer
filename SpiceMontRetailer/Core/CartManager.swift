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

    // MARK: - Add

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

    // MARK: - Remove

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
        if let existing = items.first(where: { $0.productId == productId }), let cartId = existing.id {
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

    // MARK: - Update quantity

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
            .sink { comp in
                if case .failure = comp { completion?(false) }
            } receiveValue: { [weak self] response in
                self?.applyCart(response)
                completion?(response.status == true)
            }
            .store(in: &cancellables)
    }

    func updateQuantity(productId: Int, variantId: Int? = nil, quantity: Int, completion: ((Bool) -> Void)? = nil) {
        if let existing = items.first(where: { $0.productId == productId && (variantId == nil || $0.variantId == variantId) }), let cartId = existing.id {
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

    // MARK: - Clear

    func clearCart(completion: ((Bool) -> Void)? = nil) {
        let headers = UserDefaultManager.shared.authHeader

        let publisher: AnyPublisher<CartActionResponse, Error> = networkService.request(
            APIRouter.cartClear, params: [:] as [String: Any], headers: headers
        )
        publisher
            .receive(on: DispatchQueue.main)
            .sink { comp in
                if case .failure = comp { completion?(false) }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.items = []
                    self?.subtotal = "0"
                    self?.discount = "0"
                    self?.deliveryCharge = "0"
                    self?.total = "0"
                    self?.couponCode = ""
                    self?.couponDiscount = "0"
                }
                completion?(response.status == true)
            }
            .store(in: &cancellables)
    }

    // MARK: - Helpers

    private func applyCart(_ response: CartResponse) {
        items = response.items ?? []
        subtotal = response.subtotal ?? "0"
        discount = response.discount ?? "0"
        deliveryCharge = response.deliveryCharge ?? "0"
        handlingCharge = response.handlingCharge ?? "0"
        packingCharge = response.packingCharge ?? "0"
        finalAmount = response.finalAmount ?? response.total ?? "0"
        total = response.total ?? "0"
        couponCode = response.couponCode ?? ""
        couponDiscount = response.couponDiscount ?? "0"
        appliedOffer = response.appliedOffer
    }

    func quantityForProduct(_ productId: Int) -> Int {
        items.first(where: { $0.productId == productId })?.quantity ?? 0
    }

    func quantity(for product: Product) -> Int {
        guard let pId = product.id else { return 0 }
        return quantityForProduct(pId)
    }

    func add(product: Product, variantId: Int? = nil) {
        guard let pId = product.id else { return }
        let vId = variantId ?? product.variants?.first?.id ?? pId
        addToCart(productId: pId, variantId: vId, quantity: 1)
    }

    func increment(product: Product, variantId: Int? = nil) {
        guard let pId = product.id else { return }
        let vId = variantId ?? product.variants?.first?.id ?? pId
        let current = quantityForProduct(pId)
        updateQuantity(productId: pId, variantId: vId, quantity: current + 1)
    }

    func decrement(product: Product, variantId: Int? = nil) {
        guard let pId = product.id else { return }
        let vId = variantId ?? product.variants?.first?.id ?? pId
        let current = quantityForProduct(pId)
        if current <= 1 {
            removeFromCart(productId: pId)
        } else {
            updateQuantity(productId: pId, variantId: vId, quantity: current - 1)
        }
    }
}
