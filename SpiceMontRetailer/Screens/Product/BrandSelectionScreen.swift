//
//  BrandSelectionScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct BrandSelectionScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @ObservedObject private var cartManager = CartManager.shared
    @State private var showCart: Bool = false

    @State private var brands: [Brand] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = HomeServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var filteredBrands: [Brand] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            return brands
        }
        return brands.filter { $0.name?.localizedCaseInsensitiveContains(searchText) == true }
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

                Text("Select Brand")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundColor(Color.spiceInk)

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

            if isLoading && brands.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        SpiceSkeletonBox(height: 44, cornerRadius: 10)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                            ForEach(1...6, id: \.self) { _ in
                                SpiceSkeletonBox(height: 140, cornerRadius: 16)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color.spiceBackground)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        // Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(Color.spiceMuted)
                                .font(.system(size: 13, weight: .semibold))
                            TextField("Search brand", text: $searchText)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.spiceCardBorder, lineWidth: 1))

                        Text("Step 1 of 3 · \(filteredBrands.count) brands available")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.spiceMuted)

                        if filteredBrands.isEmpty {
                            SpiceEmptyStateView(
                                title: "No Brands Found",
                                message: "No brands match your search query.",
                                buttonTitle: "Refresh"
                            ) {
                                loadBrands()
                            }
                            .padding(.top, 20)
                        } else {
                            // 2-Column Grid
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                                ForEach(filteredBrands) { brand in
                                    NavigationLink(destination: CategorySelectionScreen(brandName: brand.name ?? "Brand", brandId: brand.id)) {
                                        SpiceCard(padding: 12) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                if let img = brand.image, !img.isEmpty {
                                                    RemoteImage(url: img)
                                                        .frame(height: 80)
                                                        .clipShape(RoundedRectangle(cornerRadius: 9))
                                                } else {
                                                    RoundedRectangle(cornerRadius: 9)
                                                        .fill(LinearGradient(colors: [Color(hex: "#C0562F"), Color(hex: "#6E2A15")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                        .frame(height: 80)
                                                        .overlay(
                                                            Text(brand.name?.prefix(3).uppercased() ?? "BRD")
                                                                .font(.system(size: 13, weight: .heavy))
                                                                .foregroundColor(.white)
                                                        )
                                                }

                                                Text(brand.name ?? "")
                                                    .font(.system(size: 13, weight: .heavy))
                                                    .foregroundColor(Color.spiceInk)
                                                    .lineLimit(1)

                                                Text("\(brand.productsCount ?? 0) products")
                                                    .font(.system(size: 10.5, weight: .semibold))
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
                    loadBrands()
                }
                .background(Color.spiceBackground)
            }
        }
        .onAppear {
            loadBrands()
        }
        .sheet(isPresented: $showCart) {
            NavigationStack { CartScreen() }
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    private func loadBrands() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        service.fetchBrandList(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                self.brands = response.brands ?? []
            }
            .store(in: &cancellables)
    }
}
