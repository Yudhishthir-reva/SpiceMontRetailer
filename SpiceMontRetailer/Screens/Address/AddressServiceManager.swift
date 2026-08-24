//
//  AddressServiceManager.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine

class AddressServiceManager {

    var networkService: NetworkServiceManagable

    init(networkService: NetworkServiceManagable = NetworkServiceManager.shared) {
        self.networkService = networkService
    }

    func fetchAddresses(headers: RequestConstants.Header) -> AnyPublisher<AddressListResponse, Error> {
        networkService.request(APIRouter.addressList, params: [:] as [String: Any], headers: headers)
    }

    func fetchAddressDetail(
        id: Int,
        headers: RequestConstants.Header
    ) -> AnyPublisher<StatusResponse, Error> {
        networkService.request(APIRouter.addressDetail(id: id), params: [:] as [String: Any], headers: headers)
    }

    func storeAddress(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<StatusResponse, Error> {
        networkService.request(APIRouter.storeAddress, params: params, headers: headers)
    }

    func setDefaultAddress(
        id: Int,
        headers: RequestConstants.Header
    ) -> AnyPublisher<StatusResponse, Error> {
        networkService.request(APIRouter.setDefaultAddress(id: id), params: [:] as [String: Any], headers: headers)
    }

    func cityByPincode(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<CityByPincodeResponse, Error> {
        networkService.request(APIRouter.cityByPincode, params: params, headers: headers)
    }
}
