//
//  HomeServiceManager.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine

class HomeServiceManager {

    var networkService: NetworkServiceManagable

    init(networkService: NetworkServiceManagable = NetworkServiceManager.shared) {
        self.networkService = networkService
    }

    func fetchHome(headers: RequestConstants.Header) -> AnyPublisher<HomeResponse, Error> {
        networkService.request(APIRouter.home, params: [:] as [String: Any], headers: headers)
    }

    func fetchRetailerHome(headers: RequestConstants.Header) -> AnyPublisher<RetailerHomeResponse, Error> {
        networkService.request(APIRouter.home, params: [:] as [String: Any], headers: headers)
    }

    func fetchBrandList(headers: RequestConstants.Header) -> AnyPublisher<BrandListResponse, Error> {
        networkService.request(APIRouter.brandList, params: [:] as [String: Any], headers: headers)
    }

    func fetchCategoryList(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<CategoryListResponse, Error> {
        networkService.request(APIRouter.categoryList, params: params, headers: headers)
    }

    func fetchWidgetProducts(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<ProductListResponse, Error> {
        networkService.request(APIRouter.widgetProducts, params: params, headers: headers)
    }

    func fetchCategoryProducts(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<ProductListResponse, Error> {
        networkService.request(APIRouter.categoryProducts, params: params, headers: headers)
    }

    func fetchBrandProducts(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<ProductListResponse, Error> {
        networkService.request(APIRouter.brandProducts, params: params, headers: headers)
    }

    func fetchBannerProducts(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<ProductListResponse, Error> {
        networkService.request(APIRouter.bannerProducts, params: params, headers: headers)
    }
}
