//
//  SchemesScreen.swift
//  SpiceMontRetailer
//
//  Created on 24/08/26.
//

import SwiftUI
import Combine

struct SchemesScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: String = "All"
    private let filters = ["All", "Trade Scheme", "Quantity Slab", "Order Value"]

    @State private var schemes: [RetailerOfferScheme] = []
    @State private var isLoading: Bool = false
    @State private var isShowToast: Bool = false
    @State private var toastMessage: String = ""

    private let service = OrderServiceManager()
    @State private var cancellables = Set<AnyCancellable>()

    var filteredSchemes: [RetailerOfferScheme] {
        if selectedFilter == "All" {
            return schemes
        }
        return schemes.filter { ($0.type ?? "").localizedCaseInsensitiveContains(selectedFilter) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: { selectedFilter = filter }) {
                            Text(filter)
                                .font(.system(size: 11.5, weight: .bold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedFilter == filter ? Color.spicePrimary : Color.white)
                                .foregroundColor(selectedFilter == filter ? .white : Color.spiceInk)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedFilter == filter ? Color.spicePrimary : Color.spiceCardBorder, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color.white)
            .overlay(Divider().background(Color.spiceDivider), alignment: .bottom)

            if isLoading && schemes.isEmpty {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { _ in
                            SpiceSkeletonBox(height: 140, cornerRadius: 14)
                        }
                    }
                    .padding(16)
                }
            } else if filteredSchemes.isEmpty {
                VStack {
                    Spacer()
                    SpiceEmptyStateView(
                        title: "No Schemes Found",
                        message: "There are no active schemes matching your selection.",
                        buttonTitle: "Refresh"
                    ) {
                        loadSchemes()
                    }
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredSchemes) { scheme in
                            NavigationLink(destination: SchemeDetailScreen(scheme: scheme)) {
                                schemeCardView(scheme)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    loadSchemes()
                }
                .background(Color.spiceBackground)
            }
        }
        .navigationTitle("Running Schemes")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadSchemes()
        }
        .toast(isPresenting: $isShowToast, duration: 2.0, offsetY: 10, alert: {
            AlertToast(displayMode: .banner(.pop), type: .regular, title: toastMessage)
        }, onTap: nil, completion: nil)
    }

    private func loadSchemes() {
        isLoading = true
        let headers = UserDefaultManager.shared.authHeader

        service.fetchAvailableOffers(headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                isLoading = false
                if case .failure(let error) = completion {
                    toastMessage = (error as? RequestError)?.errorString ?? error.localizedDescription
                    isShowToast = true
                }
            } receiveValue: { response in
                self.schemes = response.data?.schemes ?? []
            }
            .store(in: &cancellables)
    }

    private func schemeCardView(_ scheme: RetailerOfferScheme) -> some View {
        SpiceCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(LinearGradient(colors: [Color(hex: "#C8322B"), Color(hex: "#7C1A16")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 80)
                    .overlay(
                        Text("SPECIAL TRADE SCHEME")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(10),
                        alignment: .bottomLeading
                    )

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(scheme.title ?? "Trade Scheme")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(Color.spiceInk)
                        Spacer()
                        SpiceStatusBadge(status: scheme.type?.uppercased() ?? "TRADE SCHEME")
                    }

                    if let desc = scheme.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(Color.spiceMuted)
                            .lineLimit(2)
                    }

                    HStack {
                        if let minVal = scheme.minOrderValue {
                            Text("Min Order: ₹\(String(format: "%.2f", minVal))")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)
                        }
                        Spacer()
                        if let exp = scheme.expiryDate, !exp.isEmpty {
                            Text("Valid till \(exp)")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.spiceMuted)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(12)
            }
        }
    }
}

// MARK: - Scheme Detail Screen
struct SchemeDetailScreen: View {
    let scheme: RetailerOfferScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    // Header Banner Card
                    SpiceCard(padding: 0) {
                        VStack(alignment: .leading, spacing: 0) {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(LinearGradient(colors: [Color(hex: "#C8322B"), Color(hex: "#7C1A16")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 100)
                                .overlay(
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("SPECIAL TRADE SCHEME")
                                            .font(.system(size: 13, weight: .heavy))
                                            .foregroundColor(.white)
                                        if let minVal = scheme.minOrderValue {
                                            Text("Min Order Value: ₹\(String(format: "%.2f", minVal))")
                                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                    .padding(12),
                                    alignment: .bottomLeading
                                )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(scheme.title ?? "Trade Scheme")
                                    .font(.system(size: 15, weight: .heavy))
                                    .foregroundColor(Color.spiceInk)

                                if let desc = scheme.description {
                                    Text(desc)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.spiceMuted)
                                        .lineSpacing(2)
                                }
                            }
                            .padding(14)
                        }
                    }

                    // Terms Card
                    SpiceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Terms & Conditions")
                                .font(.system(size: 12.5, weight: .heavy))
                                .foregroundColor(Color.spiceInk)

                            Text("• Trade discount is automatically calculated and applied at checkout by the backend system.\n• Retailers must maintain approved account status to claim trade schemes.\n• Scheme applicable while stocks last.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color.spiceMuted)
                                .lineSpacing(3)
                        }
                    }

                    // Action Button
                    NavigationLink(destination: BrandSelectionScreen().toolbar(.hidden, for: .tabBar)) {
                        Text("Explore Eligible Products")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.spicePrimary)
                            .cornerRadius(12)
                    }
                    .padding(.top, 6)
                }
                .padding(16)
            }
            .background(Color.spiceBackground)
        }
        .navigationTitle(scheme.title ?? "Scheme Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .toolbar(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}
