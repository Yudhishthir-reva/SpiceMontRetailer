//
//  UserDefaultManager.swift
//  SpiceMonk
//

import Foundation
import UIKit
import FirebaseMessaging

class UserDefaultManager {

    static let shared = UserDefaultManager()

    enum PersistenceKeys: String {
        case sellerId
        case userMobile
        case userPhone
        case userName
        case userEmail
        case shopName
        case shopAddress
        case whatsappNumber
        case authToken
        case refreshToken
        case tokenExpiry
        case salesmanName
        case salesmanPhone
        case customerSupportPhone
        case profilePic
        case greeting
        case gstNo
        case aadharFront
        case aadharBack
        case sellerStatus
        case deviceId
        case fcmToken
    }

    func setUserDefaultsString(value: String, key: PersistenceKeys) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }

    func setUserDefaultsBool(value: Bool, key: PersistenceKeys) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
        UserDefaults.standard.synchronize()
    }

    func getUserDefaultsString(key: PersistenceKeys) -> String {
        UserDefaults.standard.value(forKey: key.rawValue) as? String ?? ""
    }

    func getUserDefaultsBool(key: PersistenceKeys) -> Bool {
        UserDefaults.standard.value(forKey: key.rawValue) as? Bool ?? false
    }

    /// Stores when the access token stops being usable, derived from the `expires_in` seconds the
    /// login response carries, so a refresh can be triggered before a request is rejected.
    func setTokenExpiry(secondsFromNow: Int?) {
        guard let secondsFromNow, secondsFromNow > 0 else {
            UserDefaults.standard.removeObject(forKey: PersistenceKeys.tokenExpiry.rawValue)
            return
        }
        let expiry = Date().addingTimeInterval(TimeInterval(secondsFromNow))
        UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: PersistenceKeys.tokenExpiry.rawValue)
    }

    var tokenExpiry: Date? {
        let stored = UserDefaults.standard.double(forKey: PersistenceKeys.tokenExpiry.rawValue)
        guard stored > 0 else { return nil }
        return Date(timeIntervalSince1970: stored)
    }

    var isUserLoggedIn: Bool {
        !getUserDefaultsString(key: .authToken).isEmptyString
    }

    var authHeader: RequestConstants.Header {
        let token = getUserDefaultsString(key: .authToken)
        guard !token.isEmptyString else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }

    var fcmToken: String {
        let stored = getUserDefaultsString(key: .fcmToken)
        if !stored.isEmpty {
            return stored
        }
        if let liveToken = Messaging.messaging().fcmToken, !liveToken.isEmpty {
            setUserDefaultsString(value: liveToken, key: .fcmToken)
            return liveToken
        }
        return ""
    }

    var deviceId: String {
        let fcm = fcmToken
        if !fcm.isEmpty {
            return fcm
        }
        let existing = getUserDefaultsString(key: .deviceId)
        if !existing.isEmpty {
            return existing
        }
        let newId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        setUserDefaultsString(value: newId, key: .deviceId)
        return newId
    }

    var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        if !identifier.isEmpty {
            return identifier
        }
        return UIDevice.current.model
    }

    var deviceInfoJSONString: String {
        let id = !fcmToken.isEmpty ? fcmToken : deviceId
        let dict: [String: String] = [
            "deviceId": id,
            "deviceModel": deviceModel
        ]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{\"deviceId\":\"\(id)\",\"deviceModel\":\"\(deviceModel)\"}"
    }

    func resetUserData() {
        setUserDefaultsString(value: "", key: .sellerId)
        setUserDefaultsString(value: "", key: .userMobile)
        setUserDefaultsString(value: "", key: .userName)
        setUserDefaultsString(value: "", key: .authToken)
        setUserDefaultsString(value: "", key: .refreshToken)
        setTokenExpiry(secondsFromNow: nil)
    }
}
