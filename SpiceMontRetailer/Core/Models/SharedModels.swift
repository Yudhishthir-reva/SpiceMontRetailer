//
//  SharedModels.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import Foundation

// MARK: - Product

struct Product: Decodable, Identifiable, Hashable {
    var id: Int?
    var name: String?
    var slug: String?
    var image: String?
    var images: [ProductImage]?
    var price: String?
    var mrp: String?
    var discountPercentage: String?
    var unit: String?
    var description: String?
    var hsnCode: String?
    var inStock: Bool?
    var isNew: Bool?
    var availableQuantity: Int?
    var categoryId: Int?
    var categoryName: String?
    var brandId: Int?
    var brandName: String?
    var variants: [ProductVariant]?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, image, images, price, mrp, unit, description, variants, category, brand
        case hsnCode = "hsn_code"
        case discountPercentage = "discount_percentage"
        case inStock = "in_stock"
        case isNew = "is_new"
        case availableQuantity = "avl_qty"
        case availableQuantityAlt = "available_quantity"
        case stock = "stock"
        case categoryId = "category_id"
        case categoryName = "category_name"
        case brandId = "brand_id"
        case brandName = "brand_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        name = c.decodeStringLeniently(forKey: .name)
        slug = c.decodeStringLeniently(forKey: .slug)
        image = c.decodeStringLeniently(forKey: .image)
        images = try? c.decodeIfPresent([ProductImage].self, forKey: .images)
        hsnCode = c.decodeStringLeniently(forKey: .hsnCode)
        description = c.decodeStringLeniently(forKey: .description)
        inStock = c.decodeBoolLeniently(forKey: .inStock)
        isNew = c.decodeBoolLeniently(forKey: .isNew)
        let q1 = c.decodeIntLeniently(forKey: .availableQuantity)
        let q2 = c.decodeIntLeniently(forKey: .availableQuantityAlt)
        let q3 = c.decodeIntLeniently(forKey: .stock)
        availableQuantity = q1 ?? q2 ?? q3
        categoryId = c.decodeIntLeniently(forKey: .categoryId)
        brandId = c.decodeIntLeniently(forKey: .brandId)

        let catStr = c.decodeStringLeniently(forKey: .category)
        let catNameStr = c.decodeStringLeniently(forKey: .categoryName)
        categoryName = (catStr != nil && !catStr!.isEmpty) ? catStr : catNameStr

        let brandStr = c.decodeStringLeniently(forKey: .brand)
        let brandNameStr = c.decodeStringLeniently(forKey: .brandName)
        brandName = (brandStr != nil && !brandStr!.isEmpty) ? brandStr : brandNameStr

        variants = try? c.decodeIfPresent([ProductVariant].self, forKey: .variants)

        let p = c.decodeStringLeniently(forKey: .price)
        let m = c.decodeStringLeniently(forKey: .mrp)
        let u = c.decodeStringLeniently(forKey: .unit)
        let d = c.decodeStringLeniently(forKey: .discountPercentage)

        price = p ?? variants?.first?.price
        mrp = m ?? variants?.first?.mrp
        unit = u ?? variants?.first?.unit
        discountPercentage = d
    }

    /// Manual memberwise init for previews / testing.
    init(
        id: Int? = nil, name: String? = nil, slug: String? = nil,
        image: String? = nil, images: [ProductImage]? = nil,
        price: String? = nil, mrp: String? = nil, discountPercentage: String? = nil,
        unit: String? = nil, description: String? = nil,
        hsnCode: String? = nil, inStock: Bool? = true, isNew: Bool? = false,
        availableQuantity: Int? = nil,
        categoryId: Int? = nil, categoryName: String? = nil,
        brandId: Int? = nil, brandName: String? = nil,
        variants: [ProductVariant]? = nil
    ) {
        self.id = id; self.name = name; self.slug = slug
        self.image = image; self.images = images
        self.price = price; self.mrp = mrp; self.discountPercentage = discountPercentage
        self.unit = unit; self.description = description; self.hsnCode = hsnCode
        self.inStock = inStock; self.isNew = isNew
        self.availableQuantity = availableQuantity
        self.categoryId = categoryId; self.categoryName = categoryName
        self.brandId = brandId; self.brandName = brandName
        self.variants = variants
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Product, rhs: Product) -> Bool { lhs.id == rhs.id }

    var title: String? { name }
    var displayPrice: String { price?.priceLabel ?? "₹0" }
    var displayMRP: String { mrp?.priceLabel ?? "" }

    var hasDiscount: Bool {
        guard let p = Double(price ?? ""), let m = Double(mrp ?? ""), m > p else { return false }
        return true
    }

    var discountText: String {
        if let d = discountPercentage, !d.isEmpty, d != "0" { return "\(d)% OFF" }
        guard let p = Double(price ?? ""), let m = Double(mrp ?? ""), m > p else { return "" }
        let pct = Int(((m - p) / m) * 100)
        return pct > 0 ? "\(pct)% OFF" : ""
    }
}

struct ProductImage: Decodable, Hashable {
    var id: Int?
    var image: String?

    enum CodingKeys: String, CodingKey { case id, image }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        image = c.decodeStringLeniently(forKey: .image)
    }
}

struct ProductVariant: Decodable, Identifiable, Hashable {
    var id: Int?
    var unit: String?
    var variantName: String?
    var price: String?
    var mrp: String?
    var gst: String?
    var availableQuantity: Int?
    var minOrderQuantity: Int?
    var maxOrderQuantity: Int?

    enum CodingKeys: String, CodingKey {
        case id, unit, price, mrp, gst
        case variantName = "variant_name"
        case availableQuantity = "avl_qty"
        case availableQuantityAlt = "available_quantity"
        case stock = "stock"
        case minOrderQuantity = "min_order_qty"
        case maxOrderQuantity = "max_order_qty"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        let vName = c.decodeStringLeniently(forKey: .variantName)
        let u = c.decodeStringLeniently(forKey: .unit)
        unit = (vName != nil && !vName!.isEmpty) ? vName : u
        variantName = vName ?? u
        price = c.decodeStringLeniently(forKey: .price)
        mrp = c.decodeStringLeniently(forKey: .mrp)
        gst = c.decodeStringLeniently(forKey: .gst)
        let avl1 = c.decodeIntLeniently(forKey: .availableQuantity)
        let avl2 = c.decodeIntLeniently(forKey: .availableQuantityAlt)
        let avl3 = c.decodeIntLeniently(forKey: .stock)
        availableQuantity = avl1 ?? avl2 ?? avl3
        minOrderQuantity = c.decodeIntLeniently(forKey: .minOrderQuantity)
        maxOrderQuantity = c.decodeIntLeniently(forKey: .maxOrderQuantity)
    }

    init(
        id: Int? = nil,
        unit: String? = nil,
        variantName: String? = nil,
        price: String? = nil,
        mrp: String? = nil,
        gst: String? = nil,
        availableQuantity: Int? = nil,
        minOrderQuantity: Int? = nil,
        maxOrderQuantity: Int? = nil
    ) {
        self.id = id
        self.unit = unit
        self.variantName = variantName
        self.price = price
        self.mrp = mrp
        self.gst = gst
        self.availableQuantity = availableQuantity
        self.minOrderQuantity = minOrderQuantity
        self.maxOrderQuantity = maxOrderQuantity
    }
}

// MARK: - Banner

struct Banner: Decodable, Identifiable, Hashable {
    var id: Int?
    var image: String?
    var type: String?
    var typeId: Int?

    enum CodingKeys: String, CodingKey {
        case id, image, type
        case typeId = "type_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        image = c.decodeStringLeniently(forKey: .image)
        type = c.decodeStringLeniently(forKey: .type)
        typeId = c.decodeIntLeniently(forKey: .typeId)
    }
}

// MARK: - Brand

struct Brand: Decodable, Identifiable, Hashable {
    var id: Int?
    var name: String?
    var image: String?
    var productsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, image, logo
        case brandName = "brand_name"
        case brandImage = "brand_image"
        case brandLogo = "brand_logo"
        case productsCount = "products_count"
        case productCount = "product_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        name = c.decodeStringLeniently(forKey: .name) ?? c.decodeStringLeniently(forKey: .brandName)
        image = c.decodeStringLeniently(forKey: .image) ??
                c.decodeStringLeniently(forKey: .brandImage) ??
                c.decodeStringLeniently(forKey: .logo) ??
                c.decodeStringLeniently(forKey: .brandLogo)

        let pCount = c.decodeIntLeniently(forKey: .productsCount)
        let prodCount = c.decodeIntLeniently(forKey: .productCount)
        productsCount = pCount ?? prodCount
    }

    init(id: Int? = nil, name: String? = nil, image: String? = nil, productsCount: Int? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.productsCount = productsCount
    }
}

struct BrandListResponse: Decodable {
    var status: Bool?
    var message: String?
    var brands: [Brand]?

    enum CodingKeys: String, CodingKey {
        case status, message
        case brands = "data"
        case brandList = "brands"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        let d = try? c.decodeIfPresent([Brand].self, forKey: .brands)
        let b = try? c.decodeIfPresent([Brand].self, forKey: .brandList)
        brands = d ?? b
    }
}

// MARK: - Category

struct SpiceCategory: Decodable, Identifiable, Hashable {
    var id: Int?
    var name: String?
    var image: String?
    var brandId: Int?
    var slug: String?
    var productsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, image, slug
        case categoryPic = "category_pic"
        case brandId = "brand_id"
        case productsCount = "products_count"
        case productCount = "product_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        name = c.decodeStringLeniently(forKey: .name)
        brandId = c.decodeIntLeniently(forKey: .brandId)
        slug = c.decodeStringLeniently(forKey: .slug)

        let pCount = c.decodeIntLeniently(forKey: .productsCount)
        let prodCount = c.decodeIntLeniently(forKey: .productCount)
        productsCount = pCount ?? prodCount

        let pic = c.decodeStringLeniently(forKey: .categoryPic)
        let img = c.decodeStringLeniently(forKey: .image)
        image = (pic != nil && !pic!.isEmpty) ? pic : img
    }

    init(
        id: Int? = nil,
        name: String? = nil,
        image: String? = nil,
        brandId: Int? = nil,
        slug: String? = nil,
        productsCount: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.image = image
        self.brandId = brandId
        self.slug = slug
        self.productsCount = productsCount
    }
}

struct CategoryListResponse: Decodable {
    var status: Bool?
    var message: String?
    var categories: [SpiceCategory]?

    enum CodingKeys: String, CodingKey {
        case status, message
        case categories = "data"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        categories = try? c.decodeIfPresent([SpiceCategory].self, forKey: .categories)
    }
}

// MARK: - Widget

struct HomeWidget: Decodable, Identifiable, Hashable {
    var id: Int?
    var title: String?
    var type: String?
    var products: [Product]?

    enum CodingKeys: String, CodingKey { case id, title, type, products }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        title = c.decodeStringLeniently(forKey: .title)
        type = c.decodeStringLeniently(forKey: .type)
        products = try? c.decodeIfPresent([Product].self, forKey: .products)
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: HomeWidget, rhs: HomeWidget) -> Bool { lhs.id == rhs.id }
}

// MARK: - Home Response

struct HomeResponse: Decodable {
    var status: Bool?
    var banners: [Banner]?
    var categories: [SpiceCategory]?
    var widgets: [HomeWidget]?

    enum CodingKeys: String, CodingKey { case status, banners, categories, widgets }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        banners = try? c.decodeIfPresent([Banner].self, forKey: .banners)
        categories = try? c.decodeIfPresent([SpiceCategory].self, forKey: .categories)
        widgets = try? c.decodeIfPresent([HomeWidget].self, forKey: .widgets)
    }
}

// MARK: - Retailer Home Models

struct RetailerUser: Decodable, Hashable {
    var greeting: String?
    var sellerId: String?
    var name: String?
    var shopName: String?
    var address: String?
    var mobile: String?
    var profilePic: String?

    enum CodingKeys: String, CodingKey {
        case greeting, name, address, mobile
        case sellerId = "seller_id"
        case shopName = "shop_name"
        case profilePic = "profile_pic"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        greeting = c.decodeStringLeniently(forKey: .greeting)
        sellerId = c.decodeStringLeniently(forKey: .sellerId)
        name = c.decodeStringLeniently(forKey: .name)
        shopName = c.decodeStringLeniently(forKey: .shopName)
        address = c.decodeStringLeniently(forKey: .address)
        mobile = c.decodeStringLeniently(forKey: .mobile)
        profilePic = c.decodeStringLeniently(forKey: .profilePic)
    }
}

struct RetailerHomeResponse: Decodable {
    var status: Bool?
    var greeting: String?
    var sellerName: String?
    var shopName: String?
    var address: String?
    var user: RetailerUser?
    var accountStatus: String?
    var message: String?
    var widgets: [RetailerWidget]?

    enum CodingKeys: String, CodingKey {
        case status, greeting, address, user, message
        case sellerName = "seller_name"
        case shopName = "shop_name"
        case accountStatus = "account_status"
        case widgets = "data"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        greeting = c.decodeStringLeniently(forKey: .greeting)
        sellerName = c.decodeStringLeniently(forKey: .sellerName)
        shopName = c.decodeStringLeniently(forKey: .shopName)
        address = c.decodeStringLeniently(forKey: .address)
        user = try? c.decodeIfPresent(RetailerUser.self, forKey: .user)
        accountStatus = c.decodeStringLeniently(forKey: .accountStatus)
        message = c.decodeStringLeniently(forKey: .message)
        widgets = try? c.decodeIfPresent([RetailerWidget].self, forKey: .widgets)
    }
}

struct RetailerQuickActionItem: Decodable, Identifiable, Hashable {
    var actionType: String?
    var label: String?
    var image: String?
    var sortOrder: Int?

    var id: String { actionType ?? label ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case label, image
        case actionType = "action_type"
        case sortOrder = "sort_order"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        actionType = c.decodeStringLeniently(forKey: .actionType)
        label = c.decodeStringLeniently(forKey: .label)
        image = c.decodeStringLeniently(forKey: .image)
        sortOrder = c.decodeIntLeniently(forKey: .sortOrder)
    }
}

struct RetailerWidget: Decodable, Identifiable {
    var widgetId: Int?
    var type: String?
    var layout: String?
    var title: String?
    var sortOrder: Int?

    // Typed data holders for dynamic widget response payloads
    var banners: [RetailerBannerItem]?
    var quickActions: [RetailerQuickActionItem]?
    var runningOrder: RetailerOrderData?
    var recentOrders: [RetailerOrderData]?
    var ledgerSummary: RetailerLedgerData?
    var salesman: RetailerSalesmanData?
    var customerSupport: RetailerSupportData?
    var placeOrderLabel: RetailerPlaceOrderData?

    var id: Int { widgetId ?? UUID().hashValue }

    enum CodingKeys: String, CodingKey {
        case type, layout, title, data
        case widgetId = "widget_id"
        case sortOrder = "sort_order"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        widgetId = c.decodeIntLeniently(forKey: .widgetId)
        type = c.decodeStringLeniently(forKey: .type)
        layout = c.decodeStringLeniently(forKey: .layout)
        title = c.decodeStringLeniently(forKey: .title)
        sortOrder = c.decodeIntLeniently(forKey: .sortOrder)

        switch type {
        case "banner":
            banners = try? c.decodeIfPresent([RetailerBannerItem].self, forKey: .data)
        case "quick_action":
            quickActions = try? c.decodeIfPresent([RetailerQuickActionItem].self, forKey: .data)
        case "running_order":
            runningOrder = try? c.decodeIfPresent(RetailerOrderData.self, forKey: .data)
        case "recent_order":
            recentOrders = try? c.decodeIfPresent([RetailerOrderData].self, forKey: .data)
        case "ledger_summary":
            ledgerSummary = try? c.decodeIfPresent(RetailerLedgerData.self, forKey: .data)
        case "salesman":
            salesman = try? c.decodeIfPresent(RetailerSalesmanData.self, forKey: .data)
        case "customer_support":
            customerSupport = try? c.decodeIfPresent(RetailerSupportData.self, forKey: .data)
        case "place_new_order":
            placeOrderLabel = try? c.decodeIfPresent(RetailerPlaceOrderData.self, forKey: .data)
        default:
            break
        }
    }
}

struct RetailerBannerItem: Decodable, Identifiable, Hashable {
    var id: Int?
    var image: String?
    var actionUrl: String?
    var description: String?
    var sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, image, description
        case actionUrl = "action_url"
        case sortOrder = "sort_order"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        image = c.decodeStringLeniently(forKey: .image)
        actionUrl = c.decodeStringLeniently(forKey: .actionUrl)
        description = c.decodeStringLeniently(forKey: .description)
        sortOrder = c.decodeIntLeniently(forKey: .sortOrder)
    }
}

struct RetailerOrderData: Decodable, Identifiable, Hashable {
    var idNum: Int?
    var orderId: String?
    var totalPrice: String?
    var status: String?
    var date: String?

    var id: String { orderId ?? "\(idNum ?? UUID().hashValue)" }

    enum CodingKeys: String, CodingKey {
        case id, status, date
        case orderId = "order_id"
        case totalPrice = "total_price"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        idNum = c.decodeIntLeniently(forKey: .id)
        orderId = c.decodeStringLeniently(forKey: .orderId)
        totalPrice = c.decodeStringLeniently(forKey: .totalPrice)
        status = c.decodeStringLeniently(forKey: .status)
        date = c.decodeStringLeniently(forKey: .date)
    }
}

struct RetailerLedgerData: Decodable, Hashable {
    var totalAmount: String?
    var pendingAmount: String?
    var paidAmount: String?

    enum CodingKeys: String, CodingKey {
        case totalAmount = "total_amount"
        case pendingAmount = "pending_amount"
        case paidAmount = "paid_amount"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalAmount = c.decodeStringLeniently(forKey: .totalAmount)
        pendingAmount = c.decodeStringLeniently(forKey: .pendingAmount)
        paidAmount = c.decodeStringLeniently(forKey: .paidAmount)
    }
}

struct RetailerSalesmanData: Decodable, Hashable {
    var salesmanId: Int?
    var name: String?
    var contact: String?
    var phone: String?
    var mobile: String?

    enum CodingKeys: String, CodingKey {
        case name, contact, phone, mobile
        case salesmanId = "salesman_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        salesmanId = c.decodeIntLeniently(forKey: .salesmanId)
        name = c.decodeStringLeniently(forKey: .name)
        contact = c.decodeStringLeniently(forKey: .contact)
        phone = c.decodeStringLeniently(forKey: .phone)
        mobile = c.decodeStringLeniently(forKey: .mobile)
    }
}

struct RetailerSupportData: Decodable, Hashable {
    var contact: String?

    enum CodingKeys: String, CodingKey { case contact }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        contact = c.decodeStringLeniently(forKey: .contact)
    }
}

struct RetailerPlaceOrderData: Decodable, Hashable {
    var label: String?
    var color: String?

    enum CodingKeys: String, CodingKey { case label, color }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        label = c.decodeStringLeniently(forKey: .label)
        color = c.decodeStringLeniently(forKey: .color)
    }
}

// MARK: - Product List Response

struct ProductListResponse: Decodable {
    var status: Bool?
    var message: String?
    var products: [Product]?

    enum CodingKeys: String, CodingKey { case status, message, products }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        products = try? c.decodeIfPresent([Product].self, forKey: .products)
    }
}

struct RetailerProductPaginatedResponse: Decodable {
    var status: Bool?
    var message: String?
    var dataPage: RetailerProductPageData?

    enum CodingKeys: String, CodingKey {
        case status, message
        case dataPage = "data"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        dataPage = try? c.decodeIfPresent(RetailerProductPageData.self, forKey: .dataPage)
    }
}

struct RetailerProductPageData: Decodable {
    var currentPage: Int?
    var products: [Product]?
    var lastPage: Int?
    var perPage: Int?
    var total: Int?
    var nextPageUrl: String?

    enum CodingKeys: String, CodingKey {
        case total
        case currentPage = "current_page"
        case products = "data"
        case lastPage = "last_page"
        case perPage = "per_page"
        case nextPageUrl = "next_page_url"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentPage = c.decodeIntLeniently(forKey: .currentPage)
        products = try? c.decodeIfPresent([Product].self, forKey: .products)
        lastPage = c.decodeIntLeniently(forKey: .lastPage)
        perPage = c.decodeIntLeniently(forKey: .perPage)
        total = c.decodeIntLeniently(forKey: .total)
        nextPageUrl = c.decodeStringLeniently(forKey: .nextPageUrl)
    }
}

// MARK: - Retailer Offers & Schemes

struct RetailerOfferScheme: Decodable, Identifiable, Hashable {
    var id: Int?
    var type: String?
    var title: String?
    var discountType: String?
    var discountValue: Double?
    var minOrderValue: Double?
    var productId: Int?
    var description: String?
    var eligible: Bool?
    var discountAmount: Double?
    var expiryDate: String?

    enum CodingKeys: String, CodingKey {
        case id, type, title, description, eligible
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case minOrderValue = "min_order_value"
        case productId = "product_id"
        case discountAmount = "discount_amount"
        case expiryDate = "expiry_date"
        case validTill = "valid_till"
        case endDate = "end_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        type = c.decodeStringLeniently(forKey: .type)
        title = c.decodeStringLeniently(forKey: .title)
        discountType = c.decodeStringLeniently(forKey: .discountType)
        discountValue = try? c.decodeIfPresent(Double.self, forKey: .discountValue)
        minOrderValue = try? c.decodeIfPresent(Double.self, forKey: .minOrderValue)
        productId = c.decodeIntLeniently(forKey: .productId)
        description = c.decodeStringLeniently(forKey: .description)
        eligible = c.decodeBoolLeniently(forKey: .eligible)
        discountAmount = try? c.decodeIfPresent(Double.self, forKey: .discountAmount)
        expiryDate = c.decodeStringLeniently(forKey: .expiryDate) ?? c.decodeStringLeniently(forKey: .validTill) ?? c.decodeStringLeniently(forKey: .endDate)
    }
}

struct RetailerQuantitySlab: Decodable, Identifiable, Hashable {
    var id: Int?
    var type: String?
    var title: String?
    var minQty: Int?
    var rewardType: String?
    var discountValue: Double?
    var giftDescription: String?
    var productId: Int?
    var description: String?
    var eligible: Bool?
    var discountAmount: Double?

    enum CodingKeys: String, CodingKey {
        case id, type, title, description, eligible
        case minQty = "min_qty"
        case rewardType = "reward_type"
        case discountValue = "discount_value"
        case giftDescription = "gift_description"
        case productId = "product_id"
        case discountAmount = "discount_amount"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        type = c.decodeStringLeniently(forKey: .type)
        title = c.decodeStringLeniently(forKey: .title)
        minQty = c.decodeIntLeniently(forKey: .minQty)
        rewardType = c.decodeStringLeniently(forKey: .rewardType)
        discountValue = try? c.decodeIfPresent(Double.self, forKey: .discountValue)
        giftDescription = c.decodeStringLeniently(forKey: .giftDescription)
        productId = c.decodeIntLeniently(forKey: .productId)
        description = c.decodeStringLeniently(forKey: .description)
        eligible = c.decodeBoolLeniently(forKey: .eligible)
        discountAmount = try? c.decodeIfPresent(Double.self, forKey: .discountAmount)
    }
}

struct RetailerOffersResponse: Decodable {
    var status: Bool?
    var cartTotal: Double?
    var data: RetailerOffersData?

    enum CodingKeys: String, CodingKey {
        case status, data
        case cartTotal = "cart_total"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        cartTotal = try? c.decodeIfPresent(Double.self, forKey: .cartTotal)
        data = try? c.decodeIfPresent(RetailerOffersData.self, forKey: .data)
    }
}

struct RetailerOffersData: Decodable {
    var schemes: [RetailerOfferScheme]?
    var slabs: [RetailerQuantitySlab]?

    enum CodingKeys: String, CodingKey { case schemes, slabs }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemes = try? c.decodeIfPresent([RetailerOfferScheme].self, forKey: .schemes)
        slabs = try? c.decodeIfPresent([RetailerQuantitySlab].self, forKey: .slabs)
    }
}

struct RetailerOfferApplyResponse: Decodable {
    var status: Bool?
    var message: String?
    var data: RetailerOfferApplyData?

    enum CodingKeys: String, CodingKey { case status, message, data }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        data = try? c.decodeIfPresent(RetailerOfferApplyData.self, forKey: .data)
    }
}

struct RetailerOfferApplyData: Decodable {
    var offerId: Int?
    var offerTitle: String?
    var rewardType: String?
    var discountAmount: Double?
    var giftDescription: String?
    var finalAmount: Double?

    enum CodingKeys: String, CodingKey {
        case rewardType = "reward_type"
        case discountAmount = "discount_amount"
        case giftDescription = "gift_description"
        case finalAmount = "final_amount"
        case offerId = "offer_id"
        case offerTitle = "offer_title"
        case slabId = "slab_id"
        case slabTitle = "slab_title"
        case promotionId = "promotion_id"
        case title
        case type
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pId = c.decodeIntLeniently(forKey: .promotionId)
        let oId = c.decodeIntLeniently(forKey: .offerId)
        let sId = c.decodeIntLeniently(forKey: .slabId)
        offerId = pId ?? oId ?? sId

        let title1 = c.decodeStringLeniently(forKey: .title)
        let oTitle = c.decodeStringLeniently(forKey: .offerTitle)
        let sTitle = c.decodeStringLeniently(forKey: .slabTitle)
        offerTitle = (title1 != nil && !title1!.isEmpty) ? title1 : ((oTitle != nil && !oTitle!.isEmpty) ? oTitle : sTitle)

        let type1 = c.decodeStringLeniently(forKey: .type)
        let rType = c.decodeStringLeniently(forKey: .rewardType)
        rewardType = (type1 != nil && !type1!.isEmpty) ? type1 : rType

        discountAmount = try? c.decodeIfPresent(Double.self, forKey: .discountAmount)
        giftDescription = c.decodeStringLeniently(forKey: .giftDescription)
        finalAmount = try? c.decodeIfPresent(Double.self, forKey: .finalAmount)
    }
}

// MARK: - Product Detail Response

struct ProductDetailResponse: Decodable {
    var status: Bool?
    var message: String?
    var product: Product?

    enum CodingKeys: String, CodingKey {
        case status, message, product, data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        let prodFromData = try? c.decodeIfPresent(Product.self, forKey: .data)
        let prodFromProduct = try? c.decodeIfPresent(Product.self, forKey: .product)
        product = prodFromData ?? prodFromProduct
    }
}

// MARK: - Search Suggestion

struct SuggestionResponse: Decodable {
    var status: Bool?
    var suggestions: [String]?

    enum CodingKeys: String, CodingKey { case status, suggestions }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        suggestions = try? c.decodeIfPresent([String].self, forKey: .suggestions)
    }
}

// MARK: - Cart

struct CartResponse: Decodable {
    var status: Bool?
    var message: String?
    var items: [CartItem]?
    var subtotal: String?
    var discount: String?
    var deliveryCharge: String?
    var handlingCharge: String?
    var packingCharge: String?
    var total: String?
    var finalAmount: String?
    var couponCode: String?
    var couponDiscount: String?
    var appliedOffer: RetailerAppliedOffer?

    enum CodingKeys: String, CodingKey {
        case status, message, items, subtotal, discount, total, data
        case deliveryCharge = "delivery_charge"
        case couponCode = "coupon_code"
        case couponDiscount = "coupon_discount"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)

        if let dataObj = try? c.decodeIfPresent(RetailerCartData.self, forKey: .data) {
            items = dataObj.cartItems ?? []
            subtotal = dataObj.totalAmount ?? "0"
            discount = dataObj.discountAmount ?? "0"
            handlingCharge = dataObj.handlingCharge ?? "0"
            packingCharge = dataObj.packingCharge ?? "0"
            finalAmount = dataObj.finalAmount ?? dataObj.totalAmount ?? "0"
            total = dataObj.finalAmount ?? dataObj.totalAmount ?? "0"
            appliedOffer = dataObj.appliedOffer
        } else {
            items = (try? c.decodeIfPresent([CartItem].self, forKey: .items)) ?? []
            subtotal = c.decodeStringLeniently(forKey: .subtotal)
            discount = c.decodeStringLeniently(forKey: .discount)
            deliveryCharge = c.decodeStringLeniently(forKey: .deliveryCharge)
            total = c.decodeStringLeniently(forKey: .total)
            finalAmount = total
            couponCode = c.decodeStringLeniently(forKey: .couponCode)
            couponDiscount = c.decodeStringLeniently(forKey: .couponDiscount)
        }
    }
}

struct RetailerCartData: Decodable {
    var totalAmount: String?
    var discountAmount: String?
    var handlingCharge: String?
    var handlingTitle: String?
    var packingCharge: String?
    var packingTitle: String?
    var finalAmount: String?
    var appliedOffer: RetailerAppliedOffer?
    var cartItems: [CartItem]?

    enum CodingKeys: String, CodingKey {
        case totalAmount = "total_amount"
        case discountAmount = "discount_amount"
        case handlingCharge = "handling_charge"
        case handlingTitle = "handling_title"
        case packingCharge = "packing_charge"
        case packingTitle = "packing_title"
        case finalAmount = "final_amount"
        case appliedOffer = "applied_offer"
        case cartItems = "cart_items"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalAmount = c.decodeStringLeniently(forKey: .totalAmount)
        discountAmount = c.decodeStringLeniently(forKey: .discountAmount)
        handlingCharge = c.decodeStringLeniently(forKey: .handlingCharge)
        handlingTitle = c.decodeStringLeniently(forKey: .handlingTitle)
        packingCharge = c.decodeStringLeniently(forKey: .packingCharge)
        packingTitle = c.decodeStringLeniently(forKey: .packingTitle)
        finalAmount = c.decodeStringLeniently(forKey: .finalAmount)
        appliedOffer = try? c.decodeIfPresent(RetailerAppliedOffer.self, forKey: .appliedOffer)
        cartItems = try? c.decodeIfPresent([CartItem].self, forKey: .cartItems)
    }
}

struct CartItem: Decodable, Identifiable, Hashable {
    var id: Int?
    var productId: Int?
    var productName: String?
    var productImage: String?
    var variantId: Int?
    var variantName: String?
    var quantity: Int?
    var price: String?
    var mrp: String?
    var gst: String?
    var perPrice: String?
    var totalPrice: String?
    var availableQuantity: Int?
    var variant: ProductVariant?
    var product: Product?

    var maxStock: Int {
        if let direct = availableQuantity, direct >= 0 {
            return direct
        }
        if let v = variant, let avl = v.availableQuantity, avl >= 0 {
            return avl
        }
        if let vId = variantId, let variants = product?.variants {
            if let matched = variants.first(where: { $0.id == vId }), let avl = matched.availableQuantity, avl >= 0 {
                return avl
            }
        }
        if let vName = variantName, let variants = product?.variants {
            if let matched = variants.first(where: { $0.unit == vName || $0.variantName == vName }), let avl = matched.availableQuantity, avl >= 0 {
                return avl
            }
        }
        if let prodAvl = product?.availableQuantity, prodAvl >= 0 {
            return prodAvl
        }
        if let pId = productId {
            if let cached = CartManager.shared.getStock(productId: pId, variantId: variantId, variantName: variantName), cached >= 0 {
                return cached
            }
        }
        return 9999
    }

    var identifier: String {
        if let id = id, id > 0 { return "\(id)" }
        return "\(productId ?? 0)_\(variantId ?? 0)_\(variantName ?? "")"
    }

    enum CodingKeys: String, CodingKey {
        case id, price, mrp, gst, product, variant
        case cartId = "cart_id"
        case productId = "product_id"
        case productName = "product_name"
        case productImage = "product_image"
        case variantId = "variant_id"
        case variantName = "variant_name"
        case quantity = "quantity"
        case qty = "qty"
        case perPrice = "per_price"
        case totalPrice = "total_price"
        case availableQuantity = "avl_qty"
        case avlQuantity = "avl_quantity"
        case availableQty = "available_qty"
        case availableQuantityAlt = "available_quantity"
        case availableStock = "available_stock"
        case maxQuantity = "max_quantity"
        case maxQty = "max_qty"
        case stock = "stock"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let cId = c.decodeIntLeniently(forKey: .cartId)
        let dId = c.decodeIntLeniently(forKey: .id)
        id = cId ?? dId

        productId = c.decodeIntLeniently(forKey: .productId)
        productName = c.decodeStringLeniently(forKey: .productName)
        productImage = c.decodeStringLeniently(forKey: .productImage)
        variantId = c.decodeIntLeniently(forKey: .variantId)
        variantName = c.decodeStringLeniently(forKey: .variantName)

        let q1 = c.decodeIntLeniently(forKey: .quantity)
        let q2 = c.decodeIntLeniently(forKey: .qty)
        quantity = q1 ?? q2

        price = c.decodeStringLeniently(forKey: .price)
        mrp = c.decodeStringLeniently(forKey: .mrp)
        gst = c.decodeStringLeniently(forKey: .gst)
        perPrice = c.decodeStringLeniently(forKey: .perPrice)
        totalPrice = c.decodeStringLeniently(forKey: .totalPrice)
        let avl = c.decodeIntLeniently(forKey: .availableQuantity) ??
            c.decodeIntLeniently(forKey: .avlQuantity) ??
            c.decodeIntLeniently(forKey: .availableQty) ??
            c.decodeIntLeniently(forKey: .availableQuantityAlt) ??
            c.decodeIntLeniently(forKey: .availableStock) ??
            c.decodeIntLeniently(forKey: .maxQuantity) ??
            c.decodeIntLeniently(forKey: .maxQty) ??
            c.decodeIntLeniently(forKey: .stock)
        availableQuantity = avl
        variant = try? c.decodeIfPresent(ProductVariant.self, forKey: .variant)
        product = try? c.decodeIfPresent(Product.self, forKey: .product)
    }

    init(
        id: Int? = nil,
        productId: Int? = nil,
        productName: String? = nil,
        productImage: String? = nil,
        variantId: Int? = nil,
        variantName: String? = nil,
        quantity: Int? = 1,
        price: String? = nil,
        perPrice: String? = nil,
        totalPrice: String? = nil,
        availableQuantity: Int? = nil,
        product: Product? = nil
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.productImage = productImage
        self.variantId = variantId
        self.variantName = variantName
        self.quantity = quantity
        self.price = price
        self.perPrice = perPrice ?? price
        self.totalPrice = totalPrice
        self.availableQuantity = availableQuantity
        self.product = product
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CartItem, rhs: CartItem) -> Bool { lhs.id == rhs.id }
}

struct CartActionResponse: Decodable {
    var status: Bool?
    var message: String?

    enum CodingKeys: String, CodingKey { case status, message }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
    }
}

// MARK: - Coupon

struct CouponResponse: Decodable {
    var status: Bool?
    var coupons: [Coupon]?

    enum CodingKeys: String, CodingKey { case status, coupons }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        coupons = try? c.decodeIfPresent([Coupon].self, forKey: .coupons)
    }
}

struct Coupon: Decodable, Identifiable, Hashable {
    var id: Int?
    var code: String?
    var title: String?
    var description: String?
    var discountType: String?
    var discountValue: String?
    var minOrderAmount: String?

    enum CodingKeys: String, CodingKey {
        case id, code, title, description
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case minOrderAmount = "min_order_amount"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        code = c.decodeStringLeniently(forKey: .code)
        title = c.decodeStringLeniently(forKey: .title)
        description = c.decodeStringLeniently(forKey: .description)
        discountType = c.decodeStringLeniently(forKey: .discountType)
        discountValue = c.decodeStringLeniently(forKey: .discountValue)
        minOrderAmount = c.decodeStringLeniently(forKey: .minOrderAmount)
    }
}

// MARK: - Order

struct OrderListResponse: Decodable {
    var status: Bool?
    var message: String?
    var orders: [Order]?

    enum CodingKeys: String, CodingKey {
        case status, message, orders
        case data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)

        if let list = try? c.decodeIfPresent([Order].self, forKey: .orders) {
            orders = list
        } else if let list = try? c.decodeIfPresent([Order].self, forKey: .data) {
            orders = list
        } else if let page = try? c.decodeIfPresent(RetailerOrderPageData.self, forKey: .data) {
            orders = page.orders
        }
    }
}

struct RetailerOrderPageData: Decodable {
    var currentPage: Int?
    var orders: [Order]?
    var lastPage: Int?
    var perPage: Int?
    var total: Int?

    enum CodingKeys: String, CodingKey {
        case total
        case currentPage = "current_page"
        case orders = "data"
        case lastPage = "last_page"
        case perPage = "per_page"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentPage = c.decodeIntLeniently(forKey: .currentPage)
        orders = try? c.decodeIfPresent([Order].self, forKey: .orders)
        lastPage = c.decodeIntLeniently(forKey: .lastPage)
        perPage = c.decodeIntLeniently(forKey: .perPage)
        total = c.decodeIntLeniently(forKey: .total)
    }
}

struct Order: Decodable, Identifiable, Hashable {
    var id: Int?
    var orderNumber: String?
    var status: String?
    var statusCode: Int?
    var statusText: String?
    var statusColorHex: String?
    var total: String?
    var subtotal: String?
    var discount: String?
    var deliveryCharge: String?
    var handlingCharge: String?
    var packingCharge: String?
    var paymentMethod: String?
    var paymentStatus: String?
    var paymentMode: String?
    var createdAt: String?
    var orderDate: String?
    var orderTime: String?
    var deliveryDate: String?
    var deliveryTime: String?
    var remark: String?
    var audioRemark: String?
    var canTrack: Bool?
    var canCancel: Bool?
    var itemsCount: Int?
    var items: [OrderItem]?
    var address: Address?
    var rider: RetailerRiderInfo?
    var timeline: [RetailerTimelineItem]?
    var appliedOffer: RetailerAppliedOffer?
    var freeGift: String?

    enum CodingKeys: String, CodingKey {
        case id, total, subtotal, discount, items, address, remark, rider, timeline
        case audioRemark = "audio_remark"
        case statusStr = "status"
        case orderId = "order_id"
        case orderNumber = "order_number"
        case orderNo = "order_no"
        case totalPrice = "total_price"
        case statusText = "status_text"
        case statusColorHex = "status_color"
        case createdAt = "created_at"
        case orderDate = "order_date"
        case orderTime = "order_time"
        case deliveryDate = "delivery_date"
        case deliveryTime = "delivery_time"
        case canTrack = "can_track"
        case canCancel = "can_cancel"
        case deliveryCharge = "delivery_charge"
        case handlingCharge = "handling_charge"
        case packingCharge = "packing_charge"
        case paymentMethod = "payment_method"
        case paymentStatus = "payment_status"
        case paymentMode = "payment_mode"
        case itemsCount = "items_count"
        case orderItems = "order_items"
        case appliedOffer = "applied_offer"
        case freeGift = "free_gift"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let oId = c.decodeIntLeniently(forKey: .orderId)
        let directId = c.decodeIntLeniently(forKey: .id)
        id = oId ?? directId

        let oNo = c.decodeStringLeniently(forKey: .orderNo)
        let oNum = c.decodeStringLeniently(forKey: .orderNumber)
        orderNumber = (oNo != nil && !oNo!.isEmpty) ? oNo : oNum

        status = c.decodeStringLeniently(forKey: .statusStr)
        statusCode = c.decodeIntLeniently(forKey: .statusStr)
        statusText = c.decodeStringLeniently(forKey: .statusText)
        statusColorHex = c.decodeStringLeniently(forKey: .statusColorHex)

        let tPrice = c.decodeStringLeniently(forKey: .totalPrice)
        let tot = c.decodeStringLeniently(forKey: .total)
        total = (tPrice != nil && !tPrice!.isEmpty) ? tPrice : tot

        subtotal = c.decodeStringLeniently(forKey: .subtotal)
        discount = c.decodeStringLeniently(forKey: .discount)
        deliveryCharge = c.decodeStringLeniently(forKey: .deliveryCharge)
        handlingCharge = c.decodeStringLeniently(forKey: .handlingCharge)
        packingCharge = c.decodeStringLeniently(forKey: .packingCharge)
        paymentMethod = c.decodeStringLeniently(forKey: .paymentMethod)
        paymentStatus = c.decodeStringLeniently(forKey: .paymentStatus)
        paymentMode = c.decodeStringLeniently(forKey: .paymentMode)
        createdAt = c.decodeStringLeniently(forKey: .createdAt)
        orderDate = c.decodeStringLeniently(forKey: .orderDate)
        orderTime = c.decodeStringLeniently(forKey: .orderTime)
        deliveryDate = c.decodeStringLeniently(forKey: .deliveryDate)
        deliveryTime = c.decodeStringLeniently(forKey: .deliveryTime)
        remark = c.decodeStringLeniently(forKey: .remark)
        audioRemark = c.decodeStringLeniently(forKey: .audioRemark)
        canTrack = c.decodeBoolLeniently(forKey: .canTrack)
        canCancel = c.decodeBoolLeniently(forKey: .canCancel)
        itemsCount = c.decodeIntLeniently(forKey: .itemsCount)

        let stdItems = try? c.decodeIfPresent([OrderItem].self, forKey: .items)
        let retItems = try? c.decodeIfPresent([OrderItem].self, forKey: .orderItems)
        items = retItems ?? stdItems

        address = try? c.decodeIfPresent(Address.self, forKey: .address)
        rider = try? c.decodeIfPresent(RetailerRiderInfo.self, forKey: .rider)
        timeline = try? c.decodeIfPresent([RetailerTimelineItem].self, forKey: .timeline)
        appliedOffer = try? c.decodeIfPresent(RetailerAppliedOffer.self, forKey: .appliedOffer)
        freeGift = c.decodeStringLeniently(forKey: .freeGift)
    }

    init(
        id: Int? = nil,
        orderNumber: String? = nil,
        status: String? = nil,
        total: String? = nil,
        orderDate: String? = nil,
        createdAt: String? = nil,
        itemsCount: Int? = nil
    ) {
        self.id = id
        self.orderNumber = orderNumber
        self.status = status
        self.total = total
        self.orderDate = orderDate
        self.createdAt = createdAt ?? orderDate
        self.itemsCount = itemsCount
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Order, rhs: Order) -> Bool { lhs.id == rhs.id }

    var displayDate: String {
        if let d = orderDate, !d.isEmpty {
            if let t = orderTime, !t.isEmpty { return "\(d) \(t)" }
            return d
        }
        return createdAt ?? ""
    }

    var displayDateOnly: String {
        if let d = orderDate, !d.isEmpty { return d }
        if let created = createdAt, !created.isEmpty {
            return String(created.prefix(10))
        }
        return ""
    }

    var statusColor: String {
        if let hex = statusColorHex, !hex.isEmpty {
            return hex.replacingOccurrences(of: "#", with: "")
        }
        switch status?.lowercased() {
        case "delivered": return "167444"
        case "cancelled": return "DC2626"
        case "shipped", "out_for_delivery": return "2563EB"
        case "processing": return "F59E0B"
        default: return "6B7280"
        }
    }

    var statusLabel: String {
        if let txt = statusText, !txt.isEmpty { return txt }
        switch status?.lowercased() {
        case "pending": return "Pending"
        case "processing": return "Processing"
        case "shipped": return "Shipped"
        case "out_for_delivery": return "Out for Delivery"
        case "delivered": return "Delivered"
        case "cancelled": return "Cancelled"
        default: return status?.capitalized ?? "Unknown"
        }
    }

    var isCancellable: Bool {
        let st = (status ?? statusText ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if st.isEmpty { return true }
        if st.contains("cancel") || st.contains("deliver") || st.contains("out_for") || st.contains("out for") {
            return false
        }
        return true
    }

    var orderNumberFormatted: String {
        let num = orderNumber ?? "\(id ?? 0)"
        return num.hasPrefix("#") ? num : "#\(num)"
    }

    var totalPriceFormatted: String {
        let amt = (total?.isEmpty == false ? total : subtotal) ?? "0.00"
        return amt.priceLabel
    }

    var subtotalFormatted: String {
        let amt = (subtotal?.isEmpty == false ? subtotal : total) ?? "0.00"
        return amt.priceLabel
    }
}

struct RetailerRiderInfo: Decodable, Hashable {
    var name: String?
    var mobile: String?
    var latitude: String?
    var longitude: String?
    var address: String?
    var vehicleNo: String?

    enum CodingKeys: String, CodingKey {
        case name, mobile, latitude, longitude, address
        case vehicleNo = "vehicle_no"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.decodeStringLeniently(forKey: .name)
        mobile = c.decodeStringLeniently(forKey: .mobile)
        latitude = c.decodeStringLeniently(forKey: .latitude)
        longitude = c.decodeStringLeniently(forKey: .longitude)
        address = c.decodeStringLeniently(forKey: .address)
        vehicleNo = c.decodeStringLeniently(forKey: .vehicleNo)
    }

    init(
        name: String? = nil,
        mobile: String? = nil,
        latitude: String? = nil,
        longitude: String? = nil,
        address: String? = nil,
        vehicleNo: String? = nil
    ) {
        self.name = name
        self.mobile = mobile
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.vehicleNo = vehicleNo
    }
}

typealias RetailerRiderData = RetailerRiderInfo

struct RetailerTimelineItem: Decodable, Identifiable, Hashable {
    var key: String?
    var label: String?
    var title: String?
    var description: String?
    var isDone: Bool?
    var isActive: Bool?
    var date: String?

    var id: String { key ?? UUID().uuidString }

    enum CodingKeys: String, CodingKey {
        case key, label, title, description, date, step, done
        case isDone = "is_done"
        case isActive = "is_active"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let k1 = c.decodeStringLeniently(forKey: .key)
        let k2 = c.decodeStringLeniently(forKey: .step)
        key = k1 ?? k2

        let l1 = c.decodeStringLeniently(forKey: .label)
        let t1 = c.decodeStringLeniently(forKey: .title)
        label = l1 ?? t1
        title = t1 ?? l1

        description = c.decodeStringLeniently(forKey: .description)
        date = c.decodeStringLeniently(forKey: .date)

        let d1 = c.decodeBoolLeniently(forKey: .isDone)
        let d2 = c.decodeBoolLeniently(forKey: .done)
        isDone = d1 ?? d2

        isActive = c.decodeBoolLeniently(forKey: .isActive)
    }

    init(
        key: String? = nil,
        label: String? = nil,
        title: String? = nil,
        description: String? = nil,
        isDone: Bool? = nil,
        isActive: Bool? = nil,
        date: String? = nil
    ) {
        self.key = key
        self.label = label
        self.title = title ?? label
        self.description = description
        self.isDone = isDone
        self.isActive = isActive
        self.date = date
    }
}

struct RetailerOrderTrackResponse: Decodable {
    var status: Bool?
    var message: String?
    var data: RetailerOrderTrackData?

    enum CodingKeys: String, CodingKey { case status, message, data }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        data = try? c.decodeIfPresent(RetailerOrderTrackData.self, forKey: .data)
    }
}

struct RetailerOrderTrackData: Decodable {
    var orderId: Int?
    var orderNo: String?
    var status: Int?
    var statusText: String?
    var statusColorHex: String?
    var orderDate: String?
    var deliveryDate: String?
    var rider: RetailerRiderInfo?
    var riderLocation: String?
    var timeline: [RetailerTimelineItem]?

    enum CodingKeys: String, CodingKey {
        case status, rider, timeline
        case orderId = "order_id"
        case orderNo = "order_no"
        case statusText = "status_text"
        case statusColorHex = "status_color"
        case orderDate = "order_date"
        case deliveryDate = "delivery_date"
        case riderLocation = "rider_location"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        orderId = c.decodeIntLeniently(forKey: .orderId)
        orderNo = c.decodeStringLeniently(forKey: .orderNo)
        status = c.decodeIntLeniently(forKey: .status)
        statusText = c.decodeStringLeniently(forKey: .statusText)
        statusColorHex = c.decodeStringLeniently(forKey: .statusColorHex)
        orderDate = c.decodeStringLeniently(forKey: .orderDate)
        deliveryDate = c.decodeStringLeniently(forKey: .deliveryDate)
        riderLocation = c.decodeStringLeniently(forKey: .riderLocation)
        rider = try? c.decodeIfPresent(RetailerRiderInfo.self, forKey: .rider)
        timeline = try? c.decodeIfPresent([RetailerTimelineItem].self, forKey: .timeline)
    }

    init(
        orderId: Int? = nil,
        orderNo: String? = nil,
        status: Int? = nil,
        statusText: String? = nil,
        statusColorHex: String? = nil,
        orderDate: String? = nil,
        deliveryDate: String? = nil,
        rider: RetailerRiderInfo? = nil,
        riderLocation: String? = nil,
        timeline: [RetailerTimelineItem]? = nil
    ) {
        self.orderId = orderId
        self.orderNo = orderNo
        self.status = status
        self.statusText = statusText
        self.statusColorHex = statusColorHex
        self.orderDate = orderDate
        self.deliveryDate = deliveryDate
        self.rider = rider
        self.riderLocation = riderLocation
        self.timeline = timeline
    }
}

struct RetailerAppliedOffer: Decodable, Hashable {
    var type: String?
    var id: Int?
    var title: String?
    var discountType: String?
    var discountValue: Double?
    var discountAmount: Double?
    var giftDescription: String?
    var finalAmount: Double?

    init(
        type: String? = nil,
        id: Int? = nil,
        title: String? = nil,
        discountType: String? = nil,
        discountValue: Double? = nil,
        discountAmount: Double? = nil,
        giftDescription: String? = nil,
        finalAmount: Double? = nil
    ) {
        self.type = type
        self.id = id
        self.title = title
        self.discountType = discountType
        self.discountValue = discountValue
        self.discountAmount = discountAmount
        self.giftDescription = giftDescription
        self.finalAmount = finalAmount
    }

    enum CodingKeys: String, CodingKey {
        case type, id, title
        case promotionId = "promotion_id"
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case discountAmount = "discount_amount"
        case giftDescription = "gift_description"
        case finalAmount = "final_amount"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = c.decodeStringLeniently(forKey: .type)
        let pId = c.decodeIntLeniently(forKey: .promotionId)
        let dId = c.decodeIntLeniently(forKey: .id)
        id = pId ?? dId
        title = c.decodeStringLeniently(forKey: .title)
        discountType = c.decodeStringLeniently(forKey: .discountType)
        discountValue = try? c.decodeIfPresent(Double.self, forKey: .discountValue)
        discountAmount = try? c.decodeIfPresent(Double.self, forKey: .discountAmount)
        giftDescription = c.decodeStringLeniently(forKey: .giftDescription)
        finalAmount = try? c.decodeIfPresent(Double.self, forKey: .finalAmount)
    }

    var schemeTitle: String? { title }
    var discountText: String? {
        if let amt = discountAmount, amt > 0 {
            return "₹\(String(format: "%.2f", amt)) saved on this order"
        }
        if let gift = giftDescription, !gift.isEmpty {
            return "Free Gift: \(gift)"
        }
        return nil
    }
}

typealias CartAppliedOffer = RetailerAppliedOffer

struct OrderItem: Decodable, Identifiable, Hashable {
    var rowId: String = UUID().uuidString
    var id: Int?
    var productId: Int?
    var productName: String?
    var productImage: String?
    var variantId: Int?
    var variantName: String?
    var quantity: Int?
    var price: String?
    var totalPrice: String?
    var mrp: String?
    var gst: String?
    var unit: String?

    var identifier: String {
        "\(rowId)_\(id ?? 0)_\(productId ?? 0)_\(variantId ?? 0)"
    }

    enum CodingKeys: String, CodingKey {
        case id, quantity, price, unit, mrp, gst
        case productId = "product_id"
        case productName = "product_name"
        case productImage = "product_image"
        case variantId = "variant_id"
        case variantName = "variant_name"
        case qty = "qty"
        case perPrice = "per_price"
        case totalPrice = "total_price"
    }

    init(from decoder: Decoder) throws {
        rowId = UUID().uuidString
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let pId = c.decodeIntLeniently(forKey: .productId)
        let dId = c.decodeIntLeniently(forKey: .id)
        id = dId ?? pId
        productId = pId ?? dId

        productName = c.decodeStringLeniently(forKey: .productName)
        productImage = c.decodeStringLeniently(forKey: .productImage)
        variantId = c.decodeIntLeniently(forKey: .variantId)

        let vName = c.decodeStringLeniently(forKey: .variantName)
        let u = c.decodeStringLeniently(forKey: .unit)
        unit = (vName != nil && !vName!.isEmpty) ? vName : u
        variantName = vName

        let q1 = c.decodeIntLeniently(forKey: .quantity)
        let q2 = c.decodeIntLeniently(forKey: .qty)
        quantity = q1 ?? q2

        let p1 = c.decodeStringLeniently(forKey: .price)
        let p2 = c.decodeStringLeniently(forKey: .perPrice)
        price = (p2 != nil && !p2!.isEmpty) ? p2 : p1

        totalPrice = c.decodeStringLeniently(forKey: .totalPrice)
        mrp = c.decodeStringLeniently(forKey: .mrp)
        gst = c.decodeStringLeniently(forKey: .gst)
    }

    init(
        id: Int? = nil,
        productId: Int? = nil,
        productName: String? = nil,
        productImage: String? = nil,
        variantId: Int? = nil,
        variantName: String? = nil,
        unit: String? = nil,
        quantity: Int? = nil,
        price: String? = nil,
        totalPrice: String? = nil,
        mrp: String? = nil,
        gst: String? = nil
    ) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.productImage = productImage
        self.variantId = variantId
        self.variantName = variantName
        self.unit = unit
        self.quantity = quantity
        self.price = price
        self.totalPrice = totalPrice
        self.mrp = mrp
        self.gst = gst
    }
}

struct OrderDetailResponse: Decodable {
    var status: Bool?
    var message: String?
    var order: Order?

    enum CodingKeys: String, CodingKey {
        case status, message, order, data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        let ordFromData = try? c.decodeIfPresent(Order.self, forKey: .data)
        let ordFromOrder = try? c.decodeIfPresent(Order.self, forKey: .order)
        order = ordFromData ?? ordFromOrder
    }
}

struct OrderPlaceResponse: Decodable {
    var status: Bool?
    var message: String?
    var orderId: Int?
    var data: RetailerOrderPlaceData?

    enum CodingKeys: String, CodingKey {
        case status, message, data
        case orderId = "order_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        data = try? c.decodeIfPresent(RetailerOrderPlaceData.self, forKey: .data)
        let directOrderId = c.decodeIntLeniently(forKey: .orderId)
        orderId = data?.orderId ?? directOrderId
    }
}

struct RetailerOrderPlaceData: Decodable {
    var orderId: Int?
    var orderNo: String?
    var totalAmount: Double?
    var discountAmount: Double?
    var handlingCharge: Double?
    var packingCharge: Double?
    var finalAmount: Double?

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderNo = "order_no"
        case totalAmount = "total_amount"
        case discountAmount = "discount_amount"
        case handlingCharge = "handling_charge"
        case packingCharge = "packing_charge"
        case finalAmount = "final_amount"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        orderId = c.decodeIntLeniently(forKey: .orderId)
        orderNo = c.decodeStringLeniently(forKey: .orderNo)
        totalAmount = try? c.decodeIfPresent(Double.self, forKey: .totalAmount)
        discountAmount = try? c.decodeIfPresent(Double.self, forKey: .discountAmount)
        handlingCharge = try? c.decodeIfPresent(Double.self, forKey: .handlingCharge)
        packingCharge = try? c.decodeIfPresent(Double.self, forKey: .packingCharge)
        finalAmount = try? c.decodeIfPresent(Double.self, forKey: .finalAmount)
    }
}

// MARK: - Address

struct Address: Decodable, Identifiable, Hashable {
    var id: Int?
    var name: String?
    var phone: String?
    var addressLine1: String?
    var addressLine2: String?
    var landmark: String?
    var city: String?
    var state: String?
    var pincode: String?
    var isDefault: Bool?
    var type: String?

    enum CodingKeys: String, CodingKey {
        case id, name, phone, landmark, city, state, pincode, type
        case addressLine1 = "address_line_1"
        case addressLine2 = "address_line_2"
        case isDefault = "is_default"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        name = c.decodeStringLeniently(forKey: .name)
        phone = c.decodeStringLeniently(forKey: .phone)
        addressLine1 = c.decodeStringLeniently(forKey: .addressLine1)
        addressLine2 = c.decodeStringLeniently(forKey: .addressLine2)
        landmark = c.decodeStringLeniently(forKey: .landmark)
        city = c.decodeStringLeniently(forKey: .city)
        state = c.decodeStringLeniently(forKey: .state)
        pincode = c.decodeStringLeniently(forKey: .pincode)
        isDefault = c.decodeBoolLeniently(forKey: .isDefault)
        type = c.decodeStringLeniently(forKey: .type)
    }

    /// Manual init for previews.
    init(id: Int? = nil, name: String? = nil, phone: String? = nil,
         addressLine1: String? = nil, addressLine2: String? = nil,
         landmark: String? = nil, city: String? = nil, state: String? = nil,
         pincode: String? = nil, isDefault: Bool? = nil, type: String? = nil) {
        self.id = id; self.name = name; self.phone = phone
        self.addressLine1 = addressLine1; self.addressLine2 = addressLine2
        self.landmark = landmark; self.city = city; self.state = state
        self.pincode = pincode; self.isDefault = isDefault; self.type = type
    }

    var fullAddress: String {
        [addressLine1, addressLine2, landmark, city, state, pincode]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
            .joined(separator: ", ")
    }
}

struct AddressListResponse: Decodable {
    var status: Bool?
    var addresses: [Address]?

    enum CodingKeys: String, CodingKey { case status, addresses }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        addresses = try? c.decodeIfPresent([Address].self, forKey: .addresses)
    }
}

struct CityByPincodeResponse: Decodable {
    var status: Bool?
    var city: String?
    var state: String?

    enum CodingKeys: String, CodingKey { case status, city, state }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        city = c.decodeStringLeniently(forKey: .city)
        state = c.decodeStringLeniently(forKey: .state)
    }
}

// MARK: - Payment

struct PaymentInitiateResponse: Decodable {
    var status: Bool?
    var message: String?
    var paymentUrl: String?
    var orderId: String?

    enum CodingKeys: String, CodingKey {
        case status, message
        case paymentUrl = "payment_url"
        case orderId = "order_id"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        paymentUrl = c.decodeStringLeniently(forKey: .paymentUrl)
        orderId = c.decodeStringLeniently(forKey: .orderId)
    }
}

struct PaymentVerifyResponse: Decodable {
    var status: Bool?
    var message: String?
    var paymentStatus: String?

    enum CodingKeys: String, CodingKey {
        case status, message
        case paymentStatus = "payment_status"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        paymentStatus = c.decodeStringLeniently(forKey: .paymentStatus)
    }
}

// MARK: - Generic status response

struct StatusResponse: Decodable {
    var status: Bool?
    var message: String?

    enum CodingKeys: String, CodingKey { case status, message }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
    }
}

// MARK: - Retailer Ledger API Models

struct RetailerLedgerResponse: Decodable {
    var status: Bool?
    var message: String?
    var summary: RetailerLedgerAPISummary?
    var data: RetailerLedgerPageData?

    enum CodingKeys: String, CodingKey {
        case status, message, summary, data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        summary = try? c.decodeIfPresent(RetailerLedgerAPISummary.self, forKey: .summary)
        data = try? c.decodeIfPresent(RetailerLedgerPageData.self, forKey: .data)
    }
}

struct RetailerLedgerAPISummary: Decodable, Hashable {
    var totalBilled: String?
    var totalPaid: String?
    var totalPending: String?
    var paymentModeWise: [String: String]?

    var totalBilledDouble: Double { Double(totalBilled ?? "0") ?? 0 }
    var totalPaidDouble: Double { Double(totalPaid ?? "0") ?? 0 }
    var totalPendingDouble: Double { Double(totalPending ?? "0") ?? 0 }

    enum CodingKeys: String, CodingKey {
        case totalBilled = "total_billed"
        case totalPaid = "total_paid"
        case totalPending = "total_pending"
        case paymentModeWise = "payment_mode_wise"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalBilled = c.decodeStringLeniently(forKey: .totalBilled)
        totalPaid = c.decodeStringLeniently(forKey: .totalPaid)
        totalPending = c.decodeStringLeniently(forKey: .totalPending)
        paymentModeWise = try? c.decodeIfPresent([String: String].self, forKey: .paymentModeWise)
    }

    init(totalBilled: String, totalPaid: String, totalPending: String, paymentModeWise: [String: String]?) {
        self.totalBilled = totalBilled
        self.totalPaid = totalPaid
        self.totalPending = totalPending
        self.paymentModeWise = paymentModeWise
    }
}

struct RetailerPageLink: Decodable, Hashable {
    var url: String?
    var label: String?
    var active: Bool?

    enum CodingKeys: String, CodingKey { case url, label, active }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        url = c.decodeStringLeniently(forKey: .url)
        label = c.decodeStringLeniently(forKey: .label)
        active = c.decodeBoolLeniently(forKey: .active)
    }
}

struct RetailerLedgerPageData: Decodable {
    var currentPage: Int?
    var orders: [RetailerLedgerOrderItem]?
    var firstPageUrl: String?
    var from: String?
    var lastPage: Int?
    var lastPageUrl: String?
    var links: [RetailerPageLink]?
    var nextPageUrl: String?
    var path: String?
    var perPage: Int?
    var prevPageUrl: String?
    var to: String?
    var total: Int?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case orders = "data"
        case firstPageUrl = "first_page_url"
        case from
        case lastPage = "last_page"
        case lastPageUrl = "last_page_url"
        case links
        case nextPageUrl = "next_page_url"
        case path
        case perPage = "per_page"
        case prevPageUrl = "prev_page_url"
        case to
        case total
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentPage = c.decodeIntLeniently(forKey: .currentPage)
        orders = try? c.decodeIfPresent([RetailerLedgerOrderItem].self, forKey: .orders)
        firstPageUrl = c.decodeStringLeniently(forKey: .firstPageUrl)
        from = c.decodeStringLeniently(forKey: .from)
        lastPage = c.decodeIntLeniently(forKey: .lastPage)
        lastPageUrl = c.decodeStringLeniently(forKey: .lastPageUrl)
        links = try? c.decodeIfPresent([RetailerPageLink].self, forKey: .links)
        nextPageUrl = c.decodeStringLeniently(forKey: .nextPageUrl)
        path = c.decodeStringLeniently(forKey: .path)
        perPage = c.decodeIntLeniently(forKey: .perPage)
        prevPageUrl = c.decodeStringLeniently(forKey: .prevPageUrl)
        to = c.decodeStringLeniently(forKey: .to)
        total = c.decodeIntLeniently(forKey: .total)
    }
}

struct RetailerLedgerOrderItem: Decodable, Identifiable, Hashable {
    var orderId: Int?
    var orderNo: String?
    var orderDate: String?
    var orderStatus: Int?
    var orderStatusText: String?
    var billedAmount: Double?
    var paidAmount: Double?
    var pendingAmount: Double?
    var paymentStatus: Int?
    var paymentStatusText: String?
    var paymentMode: String?
    var paymentHistory: [RetailerPaymentHistoryRecord]?

    var id: Int { orderId ?? UUID().hashValue }

    enum CodingKeys: String, CodingKey {
        case orderId = "order_id"
        case orderNo = "order_no"
        case orderDate = "order_date"
        case orderStatus = "order_status"
        case orderStatusText = "order_status_text"
        case billedAmount = "billed_amount"
        case paidAmount = "paid_amount"
        case pendingAmount = "pending_amount"
        case paymentStatus = "payment_status"
        case paymentStatusText = "payment_status_text"
        case paymentMode = "payment_mode"
        case paymentHistory = "payment_history"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        orderId = c.decodeIntLeniently(forKey: .orderId)
        orderNo = c.decodeStringLeniently(forKey: .orderNo)
        orderDate = c.decodeStringLeniently(forKey: .orderDate)
        orderStatus = c.decodeIntLeniently(forKey: .orderStatus)
        orderStatusText = c.decodeStringLeniently(forKey: .orderStatusText)
        paymentMode = c.decodeStringLeniently(forKey: .paymentMode)

        billedAmount = try? c.decodeIfPresent(Double.self, forKey: .billedAmount)
        if billedAmount == nil, let val = c.decodeIntLeniently(forKey: .billedAmount) { billedAmount = Double(val) }

        paidAmount = try? c.decodeIfPresent(Double.self, forKey: .paidAmount)
        if paidAmount == nil, let val = c.decodeIntLeniently(forKey: .paidAmount) { paidAmount = Double(val) }

        pendingAmount = try? c.decodeIfPresent(Double.self, forKey: .pendingAmount)
        if pendingAmount == nil, let val = c.decodeIntLeniently(forKey: .pendingAmount) { pendingAmount = Double(val) }

        paymentStatus = c.decodeIntLeniently(forKey: .paymentStatus)
        paymentStatusText = c.decodeStringLeniently(forKey: .paymentStatusText)
        paymentHistory = try? c.decodeIfPresent([RetailerPaymentHistoryRecord].self, forKey: .paymentHistory)
    }

    init(
        orderId: Int? = nil,
        orderNo: String? = nil,
        orderDate: String? = nil,
        orderStatus: Int? = nil,
        orderStatusText: String? = nil,
        billedAmount: Double? = nil,
        paidAmount: Double? = nil,
        pendingAmount: Double? = nil,
        paymentStatus: Int? = nil,
        paymentStatusText: String? = nil,
        paymentMode: String? = nil,
        paymentHistory: [RetailerPaymentHistoryRecord]? = []
    ) {
        self.orderId = orderId
        self.orderNo = orderNo
        self.orderDate = orderDate
        self.orderStatus = orderStatus
        self.orderStatusText = orderStatusText
        self.billedAmount = billedAmount
        self.paidAmount = paidAmount
        self.pendingAmount = pendingAmount
        self.paymentStatus = paymentStatus
        self.paymentStatusText = paymentStatusText
        self.paymentMode = paymentMode
        self.paymentHistory = paymentHistory
    }
}

struct RetailerPaymentHistoryRecord: Decodable, Identifiable, Hashable {
    var id: String { "\(amount ?? 0)-\(date ?? "")-\(paymentMode ?? "")" }
    var amount: Double?
    var paymentMode: String?
    var date: String?
    var remark: String?

    enum CodingKeys: String, CodingKey {
        case amount
        case paymentMode = "payment_mode"
        case date, remark
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        amount = try? c.decodeIfPresent(Double.self, forKey: .amount)
        if amount == nil, let val = c.decodeIntLeniently(forKey: .amount) { amount = Double(val) }
        paymentMode = c.decodeStringLeniently(forKey: .paymentMode)
        date = c.decodeStringLeniently(forKey: .date)
        remark = c.decodeStringLeniently(forKey: .remark)
    }
}

// MARK: - Retailer Payment History API Models

struct RetailerPaymentHistoryListResponse: Decodable {
    var status: Bool?
    var message: String?
    var summary: RetailerPaymentHistorySummary?
    var data: RetailerPaymentHistoryPageData?

    enum CodingKeys: String, CodingKey {
        case status, message, summary, data
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        summary = try? c.decodeIfPresent(RetailerPaymentHistorySummary.self, forKey: .summary)
        data = try? c.decodeIfPresent(RetailerPaymentHistoryPageData.self, forKey: .data)
    }
}

struct RetailerPaymentHistorySummary: Decodable, Hashable {
    var totalPaid: String?
    var paymentModeWise: [String: String]?

    enum CodingKeys: String, CodingKey {
        case totalPaid = "total_paid"
        case paymentModeWise = "payment_mode_wise"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalPaid = c.decodeStringLeniently(forKey: .totalPaid)
        paymentModeWise = try? c.decodeIfPresent([String: String].self, forKey: .paymentModeWise)
    }

    init(totalPaid: String?, paymentModeWise: [String: String]?) {
        self.totalPaid = totalPaid
        self.paymentModeWise = paymentModeWise
    }
}

struct RetailerPaymentHistoryPageData: Decodable {
    var currentPage: Int?
    var items: [RetailerPaymentTransactionItem]?
    var perPage: Int?
    var total: Int?

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case items = "data"
        case perPage = "per_page"
        case total
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        currentPage = c.decodeIntLeniently(forKey: .currentPage)
        items = try? c.decodeIfPresent([RetailerPaymentTransactionItem].self, forKey: .items)
        perPage = c.decodeIntLeniently(forKey: .perPage)
        total = c.decodeIntLeniently(forKey: .total)
    }
}

struct RetailerPaymentTransactionItem: Decodable, Identifiable, Hashable {
    var id: Int?
    var date: String?
    var amount: Double?
    var paymentMode: String?
    var discount: Double?
    var image: String?
    var orderId: Int?
    var orderNo: String?
    var orderDate: String?

    enum CodingKeys: String, CodingKey {
        case id, date, amount, discount, image
        case paymentMode = "payment_mode"
        case orderId = "order_id"
        case orderNo = "order_no"
        case orderDate = "order_date"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        date = c.decodeStringLeniently(forKey: .date)

        amount = try? c.decodeIfPresent(Double.self, forKey: .amount)
        if amount == nil, let val = c.decodeIntLeniently(forKey: .amount) { amount = Double(val) }

        paymentMode = c.decodeStringLeniently(forKey: .paymentMode)

        discount = try? c.decodeIfPresent(Double.self, forKey: .discount)
        if discount == nil, let val = c.decodeIntLeniently(forKey: .discount) { discount = Double(val) }

        image = c.decodeStringLeniently(forKey: .image)
        orderId = c.decodeIntLeniently(forKey: .orderId)
        orderNo = c.decodeStringLeniently(forKey: .orderNo)
        orderDate = c.decodeStringLeniently(forKey: .orderDate)
    }

    init(
        id: Int? = nil,
        orderId: Int? = nil,
        orderNo: String? = nil,
        amount: Double? = nil,
        paymentMode: String? = nil,
        date: String? = nil,
        orderDate: String? = nil,
        discount: Double? = nil,
        image: String? = nil
    ) {
        self.id = id
        self.orderId = orderId
        self.orderNo = orderNo
        self.amount = amount
        self.paymentMode = paymentMode
        self.date = date
        self.orderDate = orderDate
        self.discount = discount
        self.image = image
    }
}

// MARK: - Retailer Register API Models

struct RetailerRegisterResponse: Decodable {
    var status: Bool?
    var message: String?
    var data: RetailerRegisterData?

    enum CodingKeys: String, CodingKey { case status, message, data }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        data = try? c.decodeIfPresent(RetailerRegisterData.self, forKey: .data)
    }
}

struct RetailerRegisterData: Decodable {
    var sellerId: String?
    var name: String?
    var mobile: String?

    enum CodingKeys: String, CodingKey {
        case sellerId = "seller_id"
        case name, mobile
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sellerId = c.decodeStringLeniently(forKey: .sellerId)
        name = c.decodeStringLeniently(forKey: .name)
        mobile = c.decodeStringLeniently(forKey: .mobile)
    }
}

// MARK: - Retailer States & Cities

struct RetailerStateItem: Decodable, Identifiable, Hashable {
    var id: Int?
    var name: String?
    var code: String?
    var stateId: Int?
    var stateName: String?

    enum CodingKeys: String, CodingKey {
        case id, name, code
        case stateId = "state_id"
        case stateName = "state_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let directId = c.decodeIntLeniently(forKey: .id)
        let sId = c.decodeIntLeniently(forKey: .stateId)
        id = directId ?? sId
        stateId = sId ?? directId

        let directName = c.decodeStringLeniently(forKey: .name)
        let sName = c.decodeStringLeniently(forKey: .stateName)
        name = directName ?? sName
        stateName = sName ?? directName

        code = c.decodeStringLeniently(forKey: .code)
    }

    init(id: Int, name: String, code: String? = nil) {
        self.id = id
        self.name = name
        self.stateId = id
        self.stateName = name
        self.code = code
    }
}

struct RetailerStatesResponse: Decodable {
    var status: Bool?
    var message: String?
    var data: [RetailerStateItem]?
    var states: [RetailerStateItem]?

    var allStates: [RetailerStateItem] {
        return data ?? states ?? []
    }

    enum CodingKeys: String, CodingKey {
        case status, message, data, states
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        let d = try? c.decodeIfPresent([RetailerStateItem].self, forKey: .data)
        let s = try? c.decodeIfPresent([RetailerStateItem].self, forKey: .states)
        data = d ?? s
        states = s ?? d
    }
}

struct RetailerCityItem: Decodable, Identifiable, Hashable {
    var id: Int?
    var name: String?
    var stateId: Int?
    var cityName: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case stateId = "state_id"
        case cityName = "city_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        let directName = c.decodeStringLeniently(forKey: .name)
        let cName = c.decodeStringLeniently(forKey: .cityName)
        name = directName ?? cName
        cityName = cName ?? directName
        stateId = c.decodeIntLeniently(forKey: .stateId)
    }

    init(id: Int, name: String, stateId: Int? = nil) {
        self.id = id
        self.name = name
        self.cityName = name
        self.stateId = stateId
    }
}

struct RetailerCitiesResponse: Decodable {
    var status: Bool?
    var message: String?
    var data: [RetailerCityItem]?
    var cities: [RetailerCityItem]?

    var allCities: [RetailerCityItem] {
        return data ?? cities ?? []
    }

    enum CodingKeys: String, CodingKey {
        case status, message, data, cities
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        let d = try? c.decodeIfPresent([RetailerCityItem].self, forKey: .data)
        let s = try? c.decodeIfPresent([RetailerCityItem].self, forKey: .cities)
        data = d ?? s
        cities = s ?? d
    }
}

// MARK: - Retailer Profile API Models

struct RetailerProfileResponse: Decodable {
    var status: Bool?
    var message: String?
    var data: RetailerProfileData?

    enum CodingKeys: String, CodingKey { case status, message, data }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        data = try? c.decodeIfPresent(RetailerProfileData.self, forKey: .data)
    }
}

struct RetailerProfileData: Decodable {
    var sellerId: String?
    var name: String?
    var shopName: String?
    var mobile: String?
    var whatsappNo: String?
    var email: String?
    var address: String?
    var gstNo: String?
    var latitude: String?
    var longitude: String?
    var state: RetailerProfileState?
    var city: RetailerProfileCity?
    var profilePic: String?
    var aadharFront: String?
    var aadharBack: String?
    var status: Int?

    enum CodingKeys: String, CodingKey {
        case sellerId = "seller_id"
        case name
        case shopName = "shop_name"
        case mobile
        case whatsappNo = "whatsapp_no"
        case email
        case address
        case gstNo = "gst_no"
        case latitude
        case longitude
        case state
        case city
        case profilePic = "profile_pic"
        case aadharFront = "aadhar_front"
        case aadharBack = "aadhar_back"
        case status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sellerId = c.decodeStringLeniently(forKey: .sellerId)
        name = c.decodeStringLeniently(forKey: .name)
        shopName = c.decodeStringLeniently(forKey: .shopName)
        mobile = c.decodeStringLeniently(forKey: .mobile)
        whatsappNo = c.decodeStringLeniently(forKey: .whatsappNo)
        email = c.decodeStringLeniently(forKey: .email)
        address = c.decodeStringLeniently(forKey: .address)
        gstNo = c.decodeStringLeniently(forKey: .gstNo)
        latitude = c.decodeStringLeniently(forKey: .latitude)
        longitude = c.decodeStringLeniently(forKey: .longitude)
        state = try? c.decodeIfPresent(RetailerProfileState.self, forKey: .state)
        city = try? c.decodeIfPresent(RetailerProfileCity.self, forKey: .city)
        profilePic = c.decodeStringLeniently(forKey: .profilePic)
        aadharFront = c.decodeStringLeniently(forKey: .aadharFront)
        aadharBack = c.decodeStringLeniently(forKey: .aadharBack)
        status = c.decodeIntLeniently(forKey: .status)
    }
}

struct RetailerProfileState: Decodable {
    var id: Int?
    var name: String?

    enum CodingKeys: String, CodingKey { case id, name }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        name = c.decodeStringLeniently(forKey: .name)
    }
}

struct RetailerProfileCity: Decodable {
    var id: Int?
    var name: String?

    enum CodingKeys: String, CodingKey { case id, name }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeIntLeniently(forKey: .id)
        name = c.decodeStringLeniently(forKey: .name)
    }
}

// MARK: - Retailer Config Models

public struct RetailerConfigResponse: Decodable {
    public var status: Bool?
    public var message: String?
    public var data: RetailerConfigData?

    enum CodingKeys: String, CodingKey {
        case status, message, data
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        message = c.decodeStringLeniently(forKey: .message)
        data = try? c.decodeIfPresent(RetailerConfigData.self, forKey: .data)
    }
}

public struct RetailerConfigData: Decodable {
    public var charges: RetailerConfigCharges?
    public var customerSupport: RetailerCustomerSupport?
    public var accountDetails: RetailerAccountDetails?

    enum CodingKeys: String, CodingKey {
        case charges
        case customerSupport = "customer_support"
        case accountDetails = "account_details"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        charges = try? c.decodeIfPresent(RetailerConfigCharges.self, forKey: .charges)
        customerSupport = try? c.decodeIfPresent(RetailerCustomerSupport.self, forKey: .customerSupport)
        accountDetails = try? c.decodeIfPresent(RetailerAccountDetails.self, forKey: .accountDetails)
    }
}

public struct RetailerConfigCharges: Decodable {
    public var handlingTitle: String?
    public var handlingAmount: Double?
    public var handlingVisible: Bool?
    public var packingTitle: String?
    public var packingAmount: Double?
    public var packingVisible: Bool?

    enum CodingKeys: String, CodingKey {
        case handlingTitle = "handling_title"
        case handlingAmount = "handling_amount"
        case handlingVisible = "handling_visible"
        case packingTitle = "packing_title"
        case packingAmount = "packing_amount"
        case packingVisible = "packing_visible"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        handlingTitle = c.decodeStringLeniently(forKey: .handlingTitle)
        handlingAmount = c.decodeDoubleLeniently(forKey: .handlingAmount)
        handlingVisible = c.decodeBoolLeniently(forKey: .handlingVisible)
        packingTitle = c.decodeStringLeniently(forKey: .packingTitle)
        packingAmount = c.decodeDoubleLeniently(forKey: .packingAmount)
        packingVisible = c.decodeBoolLeniently(forKey: .packingVisible)
    }
}

public struct RetailerCustomerSupport: Decodable {
    public var number: String?

    enum CodingKeys: String, CodingKey {
        case number
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        number = c.decodeStringLeniently(forKey: .number)
    }
}

public struct RetailerAccountDetails: Decodable {
    public var accountName: String?
    public var bankName: String?
    public var ifscCode: String?
    public var branchName: String?
    public var upiId: String?
    public var qrCode: String?

    enum CodingKeys: String, CodingKey {
        case accountName = "account_name"
        case bankName = "bank_name"
        case ifscCode = "ifsc_code"
        case branchName = "branch_name"
        case upiId = "upi_id"
        case qrCode = "qr_code"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        accountName = c.decodeStringLeniently(forKey: .accountName)
        bankName = c.decodeStringLeniently(forKey: .bankName)
        ifscCode = c.decodeStringLeniently(forKey: .ifscCode)
        branchName = c.decodeStringLeniently(forKey: .branchName)
        upiId = c.decodeStringLeniently(forKey: .upiId)
        qrCode = c.decodeStringLeniently(forKey: .qrCode)
    }
}

// MARK: - Retailer Check Status Models

public struct RetailerCheckStatusResponse: Decodable {
    public var status: Bool?
    public var code: String?
    public var message: String?
    public var data: RetailerCheckStatusData?

    enum CodingKeys: String, CodingKey {
        case status, code, message, data
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = c.decodeBoolLeniently(forKey: .status)
        code = c.decodeStringLeniently(forKey: .code)
        message = c.decodeStringLeniently(forKey: .message)
        data = try? c.decodeIfPresent(RetailerCheckStatusData.self, forKey: .data)
    }
}

public struct RetailerCheckStatusData: Decodable {
    public var isMaintenance: Bool?
    public var needsUpdate: Bool?
    public var forceUpdate: Bool?
    public var hasNewVersion: Bool?
    public var currentVersion: String?
    public var minVersion: String?
    public var updateUrl: String?
    public var updateMessage: String?
    public var charges: RetailerConfigCharges?
    public var customerSupport: RetailerCustomerSupport?
    public var accountDetails: RetailerAccountDetails?

    enum CodingKeys: String, CodingKey {
        case isMaintenance = "is_maintenance"
        case needsUpdate = "needs_update"
        case forceUpdate = "force_update"
        case hasNewVersion = "has_new_version"
        case currentVersion = "current_version"
        case minVersion = "min_version"
        case updateUrl = "update_url"
        case updateMessage = "update_message"
        case charges
        case customerSupport = "customer_support"
        case accountDetails = "account_details"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        isMaintenance = c.decodeBoolLeniently(forKey: .isMaintenance)
        needsUpdate = c.decodeBoolLeniently(forKey: .needsUpdate)
        forceUpdate = c.decodeBoolLeniently(forKey: .forceUpdate)
        hasNewVersion = c.decodeBoolLeniently(forKey: .hasNewVersion)
        currentVersion = c.decodeStringLeniently(forKey: .currentVersion)
        minVersion = c.decodeStringLeniently(forKey: .minVersion)
        updateUrl = c.decodeStringLeniently(forKey: .updateUrl)
        updateMessage = c.decodeStringLeniently(forKey: .updateMessage)
        charges = try? c.decodeIfPresent(RetailerConfigCharges.self, forKey: .charges)
        customerSupport = try? c.decodeIfPresent(RetailerCustomerSupport.self, forKey: .customerSupport)
        accountDetails = try? c.decodeIfPresent(RetailerAccountDetails.self, forKey: .accountDetails)
    }
}






