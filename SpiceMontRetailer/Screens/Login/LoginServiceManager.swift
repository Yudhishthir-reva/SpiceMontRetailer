//
//  LoginServiceManager.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation
import Combine

class LoginServiceManager {

    var networkService: NetworkServiceManagable

    init(networkService: NetworkServiceManagable = NetworkServiceManager.shared) {
        self.networkService = networkService
    }

    func sendOTP(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<OTPSendModel, Error> {
        networkService.request(APIRouter.sendOTP, params: params, headers: headers)
    }

    func verifyOTP(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<OTPVerifyModel, Error> {
        networkService.request(APIRouter.verifyOTP, params: params, headers: headers)
    }

    func registerRetailer(
        params: RequestConstants.Param,
        headers: RequestConstants.Header
    ) -> AnyPublisher<RetailerRegisterResponse, Error> {
        networkService.request(APIRouter.retailerRegister, params: params, headers: headers)
    }

    func logoutRetailer(
        headers: RequestConstants.Header
    ) -> AnyPublisher<StatusResponse, Error> {
        networkService.request(APIRouter.retailerLogout, params: [:] as [String: Any], headers: headers)
    }

    func fetchRetailerStates(
        headers: RequestConstants.Header = RequestConstants.Header()
    ) -> AnyPublisher<RetailerStatesResponse, Error> {
        networkService.request(APIRouter.retailerStates, params: [:] as [String: Any], headers: headers)
    }

    func fetchRetailerCities(
        stateId: Int? = nil,
        headers: RequestConstants.Header = RequestConstants.Header()
    ) -> AnyPublisher<RetailerCitiesResponse, Error> {
        networkService.request(APIRouter.retailerCities(stateId: stateId), params: [:] as [String: Any], headers: headers)
    }

    func fetchRetailerProfile(
        headers: RequestConstants.Header
    ) -> AnyPublisher<RetailerProfileResponse, Error> {
        networkService.request(APIRouter.retailerProfile, params: [:] as [String: Any], headers: headers)
    }
}

struct OTPSendModel: Decodable {
    var status: Bool?
    var message: String?

    enum CodingKeys: String, CodingKey {
        case status, message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = container.decodeBoolLeniently(forKey: .status)
        message = container.decodeStringLeniently(forKey: .message)
    }
}

struct OTPVerifyModel: Decodable {
    var status: Bool?
    var message: String?
    var accessToken: String?
    var refreshToken: String?
    var expiresIn: Int?
    var sellerId: String?
    var mobile: String?
    var name: String?
    var isNew: Bool?

    enum CodingKeys: String, CodingKey {
        case status, message, mobile, name
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case sellerId = "seller_id"
        case isNew = "is_new"
    }

    /// Decoded field by field rather than synthesised, because the endpoint mixes quoted and
    /// unquoted scalars — see `decodeStringLeniently`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = container.decodeBoolLeniently(forKey: .status)
        message = container.decodeStringLeniently(forKey: .message)
        accessToken = container.decodeStringLeniently(forKey: .accessToken)
        refreshToken = container.decodeStringLeniently(forKey: .refreshToken)
        expiresIn = container.decodeIntLeniently(forKey: .expiresIn)
        sellerId = container.decodeStringLeniently(forKey: .sellerId)
        mobile = container.decodeStringLeniently(forKey: .mobile)
        name = container.decodeStringLeniently(forKey: .name)
        isNew = container.decodeBoolLeniently(forKey: .isNew)
    }
}
