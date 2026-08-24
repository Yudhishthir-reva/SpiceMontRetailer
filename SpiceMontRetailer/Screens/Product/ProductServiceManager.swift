//
//  ProductServiceManager.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine

class ProductServiceManager {

    var networkService: NetworkServiceManagable

    init(networkService: NetworkServiceManagable = NetworkServiceManager.shared) {
        self.networkService = networkService
    }

    func fetchDetail(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<ProductDetailResponse, Error> {
        networkService.request(APIRouter.productDetail, params: params, headers: headers)
    }

    func fetchProductList(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<RetailerProductPaginatedResponse, Error> {
        networkService.request(APIRouter.productList, params: params, headers: headers)
    }

    func fetchRelated(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<ProductListResponse, Error> {
        networkService.request(APIRouter.relatedProducts, params: params, headers: headers)
    }

    func fetchSuggestions(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<SuggestionResponse, Error> {
        networkService.request(APIRouter.productSuggestions, params: params, headers: headers)
    }

    func search(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<ProductListResponse, Error> {
        networkService.request(APIRouter.productSearch, params: params, headers: headers)
    }
}
