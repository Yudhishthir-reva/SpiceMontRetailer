//
//  CategorySelectionScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct CategorySelectionScreen: View {
    let brandName: String
    var brandId: Int? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showCart: Bool = false

    @State private var categories: [SpiceCategory] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = HomeServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var filteredCategories: [SpiceCategory] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return categories
        }
        return categories.filter { $0.name?.localizedCaseInsensitiveContains(searchText) == true }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.spiceInk)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(brandName)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Color.spiceInk)
                    Text("Select Category")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color.spiceMuted)
                }

                Spacer()

                Button(action: { showCart = true }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 17))
                            .foregroundColor(Color.spiceInk)
                            .padding(6)

                        if cartManager.itemCount > 0 {
                            Text("\(cartManager.itemCount)")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.spicePrimary)
                                .clipShape(Capsule())
                                .offset(x: 4, y: -2)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            if isLoading && categories.isEmpty {
                ScrollView {
                    VStack(spacing: 10) {
                        SpiceSkeletonBox(height: 44, cornerRadius: 10)
                        ForEach(1...5, id: \.self) { _ in
                            SpiceSkeletonBox(height: 70, cornerRadius: 12)
                        }
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.spiceMuted)
                                .font(.system(size: 13, weight: .semibold))
                            TextField("Search category in \(brandName)", text: $searchText)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

                        Text("Step 2 of 3 · \(filteredCategories.count) categories available")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.spiceMuted)

                        if filteredCategories.isEmpty {
                            SpiceEmptyStateView(
                                title: "No Categories",
                                message: "No categories available for \(brandName).",
                                buttonTitle: "Refresh"
                            ) {
                                loadCategories()
                            }
                            .padding(.top, 20)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(filteredCategories) { cat in
                                    NavigationLink(destination: ProductListingView(brandName: brandName, categoryName: cat.name ?? "Category", brandId: brandId, categoryId: cat.id)) {
                                        SpiceCard(padding: 12) {
                                            HStack(spacing: 12) {
                                                if let img = cat.image, !img.isEmpty {
                                                    RemoteImage(url: img)
                                                        .frame(width: 46, height: 46)
                                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                                } else {
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(LinearGradient(colors: [Color.spicePrimaryLight, Color(hex: "#C8E6D6")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                        .frame(width: 46, height: 46)
                                                        .overlay(
                                                            Image(systemName: "square.grid.2x2.fill")
                                                                .font(.system(size: 18))
                                                                .foregroundColor(Color.spicePrimary)
                                                        )
                                                }

                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(cat.name ?? "")
                                                        .font(.system(size: 13.5, weight: .bold))
                                                        .foregroundColor(Color.spiceInk)
                                                    if let pCount = cat.productsCount {
                                                        Text("\(pCount) products")
                                                            .font(.system(size: 11, weight: .medium))
                                                            .foregroundColor(Color.spiceMuted)
                                                    }
                                                }

                                                Spacer()

                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(Color.spiceMuted)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    loadCategories()
                }
                .background(Color.spiceBackground)
            }
        }
        .onAppear {
            loadCategories()
        }
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    private func loadCategories() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader
        var params: [String: Any] = [:]
        if let bId = brandId {
            params["brand_id"] = bId
        }

        service.fetchCategoryList(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                self.categories = response.categories ?? []
            }
            .store(in: &cancellables)
    }
}
