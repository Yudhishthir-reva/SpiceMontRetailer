//
//  CheckoutScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine
import WebKit

struct CheckoutScreen: View {

    @StateObject private var viewModel = CheckoutViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    // Address section
                    addressSection

                    // Payment method
                    paymentMethodSection

                    // Order summary
                    orderSummary

                    Color.clear.frame(height: 90)
                }
                .padding(16)
            }
            .background(AppTheme.homeCanvas)

            // Place order
            placeOrderBar
        }
        .spiceNavigationBar(title: "Checkout")
        .onAppear { viewModel.loadAddresses() }
        .sheet(isPresented: $viewModel.showAddAddress) {
            NavigationStack {
                AddAddressScreen { viewModel.loadAddresses() }
            }
        }
        .sheet(isPresented: $viewModel.showPaymentWebView) {
            if let url = viewModel.paymentURL {
                PaymentWebView(url: url) { success in
                    viewModel.showPaymentWebView = false
                    if success {
                        viewModel.verifyPayment()
                    }
                }
            }
        }
        .toast(isPresenting: $viewModel.isShowToast, duration: 1.8, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: viewModel.toastMessage)
        }, onTap: nil, completion: nil)
        .onChange(of: viewModel.orderPlaced) { _, placed in
            if placed {
                cartManager.fetchCart()
                dismiss()
            }
        }
    }

    // MARK: - Address Section

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Delivery Address")
                    .font(.appFont(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Spacer()
                Button { viewModel.showAddAddress = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add New")
                    }
                    .font(.appFont(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.brandGreen)
                }
            }

            if viewModel.isLoadingAddresses {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.addresses.isEmpty {
                Button { viewModel.showAddAddress = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppTheme.brandGreen)
                        Text("Add delivery address")
                            .font(.appFont(size: 14))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(AppTheme.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundStyle(AppTheme.brandGreen.opacity(0.4))
                    }
                }
            } else {
                ForEach(viewModel.addresses) { address in
                    addressCard(address)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    private func addressCard(_ address: Address) -> some View {
        let isSelected = viewModel.selectedAddressId == address.id

        return Button {
            viewModel.selectedAddressId = address.id
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.brandGreen : AppTheme.textMuted)
                    .font(.appFont(size: 20))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(address.name ?? "")
                            .font(.appFont(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        if address.isDefault == true {
                            Text("DEFAULT")
                                .font(.appFont(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.brandGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                    Text(address.fullAddress)
                        .font(.appFont(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                    if let phone = address.phone, !phone.isEmpty {
                        Text(phone)
                            .font(.appFont(size: 12))
                            .foregroundStyle(AppTheme.textMuted)
                    }
                }
            }
            .padding(10)
            .background(isSelected ? AppTheme.accentSoft : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? AppTheme.brandGreen : AppTheme.fieldBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Payment Method

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment Method")
                .font(.appFont(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(["cod", "online"], id: \.self) { method in
                let isSelected = viewModel.paymentMethod == method

                Button { viewModel.paymentMethod = method } label: {
                    HStack(spacing: 10) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isSelected ? AppTheme.brandGreen : AppTheme.textMuted)
                            .font(.appFont(size: 20))

                        Image(systemName: method == "cod" ? "banknote.fill" : "creditcard.fill")
                            .foregroundStyle(AppTheme.brandGreen)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(method == "cod" ? "Cash on Delivery" : "Pay Online")
                                .font(.appFont(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text(method == "cod" ? "Pay when you receive" : "UPI, Cards, Net Banking")
                                .font(.appFont(size: 12))
                                .foregroundStyle(AppTheme.textMuted)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(isSelected ? AppTheme.accentSoft : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? AppTheme.brandGreen : AppTheme.fieldBorder, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    // MARK: - Order Summary

    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Order Summary")
                .font(.appFont(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            ForEach(cartManager.items, id: \.identifier) { item in
                HStack {
                    Text(item.product?.name ?? "")
                        .font(.appFont(size: 13))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    Text("×\(item.quantity ?? 0)")
                        .font(.appFont(size: 13))
                        .foregroundStyle(AppTheme.textMuted)
                    Text(item.product?.displayPrice ?? "")
                        .font(.appFont(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .frame(width: 60, alignment: .trailing)
                }
            }

            Divider()

            HStack {
                Text("Total")
                    .font(.appFont(size: 15, weight: .bold))
                Spacer()
                Text(cartManager.total.priceLabel)
                    .font(.appFont(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.brandGreen)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    // MARK: - Place Order Bar

    private var placeOrderBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(cartManager.total.priceLabel)
                    .font(.appFont(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(viewModel.paymentMethod == "cod" ? "Cash on Delivery" : "Pay Online")
                    .font(.appFont(size: 12))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Spacer()
            PrimaryActionButton(
                title: "Place Order",
                icon: "checkmark",
                isLoading: viewModel.isPlacing
            ) {
                viewModel.placeOrder()
            }
            .frame(width: 180)
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 8, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - ViewModel

class CheckoutViewModel: ObservableObject {

    @Published var addresses: [Address] = []
    @Published var selectedAddressId: Int?
    @Published var paymentMethod = "cod"
    @Published var isLoadingAddresses = true
    @Published var isPlacing = false
    @Published var isShowToast = false
    @Published var toastMessage = ""
    @Published var showAddAddress = false
    @Published var showPaymentWebView = false
    @Published var paymentURL: URL?
    @Published var orderPlaced = false

    private var placedOrderId: Int?
    private let addressService = AddressServiceManager()
    private let orderService = OrderServiceManager()
    private var cancellables = Set<AnyCancellable>()

    func loadAddresses() {
        isLoadingAddresses = true
        let headers = UserDefaultManager.shared.authHeader

        addressService.fetchAddresses(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isLoadingAddresses = false
            } receiveValue: { [weak self] response in
                self?.addresses = response.addresses ?? []
                // Auto-select default
                if let def = self?.addresses.first(where: { $0.isDefault == true }) {
                    self?.selectedAddressId = def.id
                } else {
                    self?.selectedAddressId = self?.addresses.first?.id
                }
            }
            .store(in: &cancellables)
    }

    func placeOrder() {
        guard let addressId = selectedAddressId else {
            toastMessage = "Please select a delivery address"
            isShowToast = true
            return
        }

        isPlacing = true
        let headers = UserDefaultManager.shared.authHeader
        let params: [String: Any] = [
            "address_id": addressId,
            "payment_method": paymentMethod
        ]

        orderService.placeOrder(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isPlacing = false
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self?.isShowToast = true
                }
            } receiveValue: { [weak self] response in
                if response.status == true {
                    self?.placedOrderId = response.orderId
                    if self?.paymentMethod == "online" {
                        self?.initiatePayment()
                    } else {
                        self?.toastMessage = response.message ?? "Order placed successfully!"
                        self?.isShowToast = true
                        self?.orderPlaced = true
                    }
                } else {
                    self?.toastMessage = response.message ?? "Failed to place order"
                    self?.isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    private func initiatePayment() {
        guard let orderId = placedOrderId else { return }
        let headers = UserDefaultManager.shared.authHeader
        let params: [String: Any] = ["order_id": orderId]

        orderService.initiatePayment(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self?.isShowToast = true
                }
            } receiveValue: { [weak self] response in
                if let urlString = response.paymentUrl, let url = URL(string: urlString) {
                    self?.paymentURL = url
                    self?.showPaymentWebView = true
                } else {
                    self?.toastMessage = response.message ?? "Payment init failed"
                    self?.isShowToast = true
                }
            }
            .store(in: &cancellables)
    }

    func verifyPayment() {
        guard let orderId = placedOrderId else { return }
        let headers = UserDefaultManager.shared.authHeader
        let params: [String: Any] = ["order_id": orderId]

        orderService.verifyPayment(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    self?.isShowToast = true
                }
            } receiveValue: { [weak self] response in
                self?.toastMessage = response.message ?? "Payment verified!"
                self?.isShowToast = true
                self?.orderPlaced = true
            }
            .store(in: &cancellables)
    }
}

// MARK: - Payment WebView

struct PaymentWebView: UIViewRepresentable {
    let url: URL
    let onComplete: (Bool) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let onComplete: (Bool) -> Void

        init(onComplete: @escaping (Bool) -> Void) {
            self.onComplete = onComplete
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url?.absoluteString {
                if url.contains("payment/success") || url.contains("payment/callback") {
                    onComplete(true)
                    decisionHandler(.cancel)
                    return
                } else if url.contains("payment/failure") || url.contains("payment/cancel") {
                    onComplete(false)
                    decisionHandler(.cancel)
                    return
                }
            }
            decisionHandler(.allow)
        }
    }
}

#Preview {
    NavigationStack {
        CheckoutScreen()
    }
}
