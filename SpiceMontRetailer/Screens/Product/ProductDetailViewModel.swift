//
//  ProductDetailViewModel.swift
//  SpiceMontRetailer
//
//  Created on 25/08/26.
//

import Foundation
import Combine

final class ProductDetailViewModel: ObservableObject {
    @Published var product: Product?
    @Published var relatedProducts: [Product] = []
    @Published var isLoading: Bool = false
    @Published var isShowToast: Bool = false
    @Published var toastMessage: String = ""

    private let service = ProductServiceManager()
    private var cancellables = Set<AnyCancellable>()

    func load(productId: Int) {
        guard productId > 0 else { return }
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        let params: [String: Any] = ["product_id": productId]

        service.fetchDetail(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.product = response.product
                if let prod = response.product, let pId = prod.id {
                    if let avl = prod.availableQuantity {
                        CartManager.shared.registerStock(productId: pId, stock: avl)
                    }
                    if let variants = prod.variants {
                        for v in variants {
                            if let vAvl = v.availableQuantity {
                                CartManager.shared.registerStock(productId: pId, variantId: v.id, variantName: v.unit, stock: vAvl)
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}
