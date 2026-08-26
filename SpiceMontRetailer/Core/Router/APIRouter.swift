//
//  APIRouter.swift
//  SpiceMonk
//

enum APIRouter: RouterManagable {

    case sendOTP
    case verifyOTP
    case refreshToken
    case home
    /// Shares its path with `storeAddress`; the two differ only by HTTP method.
    case addressList
    case addressDetail(id: Int)
    case setDefaultAddress(id: Int)
    case storeAddress
    case cityByPincode
    case widgetProducts
    case categoryProducts
    case brandProducts
    case bannerProducts
    case productDetail
    case relatedProducts
    case productSuggestions
    case productSearch
    case cart
    case cartAdd
    case cartRemove
    case cartClear
    case cartUpdate
    case coupons
    case orders
    case orderDetail(id: Int)
    case orderCancel
    case orderPlace
    case paymentInitiate
    case paymentVerify
    case brandList
    case categoryList
    case productList
    case offersAvailable
    case offersApply
    case offersRemove
    case orderTrack
    case retailerLedger(page: Int, perPage: Int)
    case retailerPaymentHistory(page: Int, perPage: Int)
    case retailerRegister
    case retailerLogout
    case retailerStates
    case retailerCities(stateId: Int?)
    case retailerProfile

    var endPointUrl: String {
        switch self {
        case .sendOTP:
            return "auth/send-otp"
        case .verifyOTP:
            return "auth/verify-otp"
        case .refreshToken:
            return "auth/refresh-token"
        case .home:
            return "home"
        case .addressList:
            return "address"
        case .addressDetail(let id):
            return "address/\(id)"
        case .setDefaultAddress(let id):
            return "address/\(id)/default"
        case .storeAddress:
            return "address"
        case .cityByPincode:
            return "address/by-pincode"
        case .widgetProducts:
            return "widget/products"
        case .categoryProducts:
            return "category/products"
        case .brandProducts:
            return "brand/products"
        case .bannerProducts:
            return "banner/products"
        case .productDetail:
            return "product/detail"
        case .relatedProducts:
            return "product/related"
        case .productSuggestions:
            return "product/suggestions"
        case .productSearch:
            return "product/search"
        case .cart:
            return "cart"
        case .cartAdd:
            return "cart/add"
        case .cartRemove:
            return "cart/remove"
        case .cartClear:
            return "cart/clear"
        case .cartUpdate:
            return "cart/update"
        case .coupons:
            return "coupons"
        case .orders:
            return "order/list"
        case .orderDetail:
            return "order/detail"
        case .orderCancel:
            return "order/cancel"
        case .orderPlace:
            return "order/place"
        case .paymentInitiate:
            return "payment/initiate"
        case .paymentVerify:
            return "payment/verify"
        case .brandList:
            return "brand-list"
        case .categoryList:
            return "category-list"
        case .productList:
            return "product-list"
        case .offersAvailable:
            return "offers/available"
        case .offersApply:
            return "offers/apply"
        case .offersRemove:
            return "offers/remove"
        case .orderTrack:
            return "order/track"
        case .retailerLedger(let page, let perPage):
            return "ledger?page=\(page)&per_page=\(perPage)"
        case .retailerPaymentHistory(let page, let perPage):
            return "ledger/payment-history?page=\(page)&per_page=\(perPage)"
        case .retailerRegister:
            return "auth/register"
        case .retailerLogout:
            return "auth/logout"
        case .retailerStates:
            return "states"
        case .retailerCities(let stateId):
            if let sId = stateId {
                return "cities?state_id=\(sId)"
            }
            return "cities"
        case .retailerProfile:
            return "profile"
        }
    }

    var requestType: RequestMethodType {
        switch self {
        case .home, .addressList, .addressDetail, .cart, .coupons, .orders, .brandList, .offersAvailable, .retailerLedger, .retailerPaymentHistory, .retailerStates, .retailerCities, .retailerProfile:
            return .get
        case .cartClear:
            return .delete
        default:
            return .post
        }
    }

    var contentType: RequestContentType {
        switch self {
        case .offersApply, .offersRemove, .orderPlace, .orderDetail, .orderTrack:
            return .json
        default:
            return .multipartForm
        }
    }
}
