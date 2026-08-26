//
//  OrderServiceManager.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine

class OrderServiceManager {

    var networkService: NetworkServiceManagable

    init(networkService: NetworkServiceManagable = NetworkServiceManager.shared) {
        self.networkService = networkService
    }

    func fetchOrders(params: RequestConstants.Param = [:], headers: RequestConstants.Header) -> AnyPublisher<OrderListResponse, Error> {
        networkService.request(APIRouter.orders, params: params, headers: headers)
    }

    func fetchOrderDetail(
        id: Int,
        headers: RequestConstants.Header
    ) -> AnyPublisher<OrderDetailResponse, Error> {
        let params: [String: Any] = ["order_id": id]
        return networkService.request(APIRouter.orderDetail(id: id), params: params, headers: headers)
    }

    func cancelOrder(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<StatusResponse, Error> {
        networkService.request(APIRouter.orderCancel, params: params, headers: headers)
    }

    func placeOrder(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<OrderPlaceResponse, Error> {
        networkService.request(APIRouter.orderPlace, params: params, headers: headers)
    }

    func initiatePayment(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<PaymentInitiateResponse, Error> {
        networkService.request(APIRouter.paymentInitiate, params: params, headers: headers)
    }

    func verifyPayment(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<PaymentVerifyResponse, Error> {
        networkService.request(APIRouter.paymentVerify, params: params, headers: headers)
    }

    func fetchCoupons(headers: RequestConstants.Header) -> AnyPublisher<CouponResponse, Error> {
        networkService.request(APIRouter.coupons, params: [:] as [String: Any], headers: headers)
    }

    func fetchAvailableOffers(headers: RequestConstants.Header) -> AnyPublisher<RetailerOffersResponse, Error> {
        networkService.request(APIRouter.offersAvailable, params: [:] as [String: Any], headers: headers)
    }

    func applyOffer(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<RetailerOfferApplyResponse, Error> {
        networkService.request(APIRouter.offersApply, params: params, headers: headers)
    }

    func removeOffer(headers: RequestConstants.Header) -> AnyPublisher<StatusResponse, Error> {
        networkService.request(APIRouter.offersRemove, params: [:] as [String: Any], headers: headers)
    }

    func trackOrder(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<RetailerOrderTrackResponse, Error> {
        networkService.request(APIRouter.orderTrack, params: params, headers: headers)
    }

    func fetchRetailerLedger(
        page: Int = 1,
        perPage: Int = 15,
        headers: RequestConstants.Header
    ) -> AnyPublisher<RetailerLedgerResponse, Error> {
        networkService.request(APIRouter.retailerLedger(page: page, perPage: perPage), params: [:] as [String: Any], headers: headers)
    }

    func fetchRetailerPaymentHistory(
        page: Int = 1,
        perPage: Int = 15,
        headers: RequestConstants.Header
    ) -> AnyPublisher<RetailerPaymentHistoryListResponse, Error> {
        networkService.request(APIRouter.retailerPaymentHistory(page: page, perPage: perPage), params: [:] as [String: Any], headers: headers)
    }
}

