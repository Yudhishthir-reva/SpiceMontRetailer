//
//  SearchScreen.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI
import Combine

struct SearchScreen: View {

    @StateObject private var viewModel = SearchViewModel()
    @ObservedObject private var cartManager = CartManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            searchBar

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if !viewModel.suggestions.isEmpty && viewModel.products.isEmpty {
                suggestionsList
            } else if !viewModel.products.isEmpty {
                searchResults
            } else if viewModel.hasSearched {
                emptyState
            } else {
                searchPrompt
            }
        }
        .background(AppTheme.homeCanvas)
        .spiceNavigationBar(title: "Search")
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textMuted)

            TextField("Search spices, masalas...", text: $viewModel.query)
                .font(.system(size: 15))
                .foregroundColor(Color.black)
                .tint(Color.spicePrimary)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit { viewModel.search() }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                    viewModel.suggestions = []
                    viewModel.products = []
                    viewModel.hasSearched = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(AppTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.fieldBorder, lineWidth: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Suggestions

    private var suggestionsList: some View {
        List {
            ForEach(viewModel.suggestions, id: \.self) { suggestion in
                Button {
                    viewModel.query = suggestion
                    viewModel.search()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppTheme.textMuted)
                            .font(.system(size: 14))
                        Text(suggestion)
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .foregroundStyle(AppTheme.textMuted)
                            .font(.system(size: 13))
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Results

    private var searchResults: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 14) {
                ForEach(viewModel.products) { product in
                    NavigationLink {
                        ProductDetailScreen(productId: product.id ?? 0, initialProduct: product)
                    } label: {
                        searchResultCard(product)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private func searchResultCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                RemoteImage(url: product.image)
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                if product.hasDiscount {
                    Text(product.discountText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(AppTheme.discountBadge)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(6)
                }
            }

            Text(product.name ?? "")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)

            if let unit = product.unit, !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.textMuted)
            }

            HStack(spacing: 4) {
                Text(product.displayPrice)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.brandGreen)
                if product.hasDiscount {
                    Text(product.displayMRP)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.textMuted)
                        .strikethrough()
                }
            }
        }
        .padding(8)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        }
    }

    // MARK: - Empty / Prompt

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.textMuted)
            Text("No results found")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
            Text("Try searching with different keywords")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textMuted)
        }
        .frame(maxHeight: .infinity)
    }

    private var searchPrompt: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "leaf.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.brandGreen.opacity(0.3))
            Text("Search for spices, masalas,\ndry fruits & more")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - ViewModel

class SearchViewModel: ObservableObject {

    @Published var query = ""
    @Published var suggestions: [String] = []
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var hasSearched = false

    private let service = ProductServiceManager()
    private var cancellables = Set<AnyCancellable>()
    private var suggestionCancellable: AnyCancellable?

    init() {
        // Debounced suggestions
        suggestionCancellable = $query
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] value in
                guard let self else { return }
                if value.trim.count >= 2 {
                    self.fetchSuggestions(query: value.trim)
                } else {
                    self.suggestions = []
                }
            }
    }

    private func fetchSuggestions(query: String) {
        let params: [String: Any] = ["query": query]
        let headers = UserDefaultManager.shared.authHeader

        service.fetchSuggestions(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            receiveValue: { [weak self] response in
                self?.suggestions = response.suggestions ?? []
            }
            .store(in: &cancellables)
    }

    func search() {
        guard query.trim.count >= 2 else { return }
        isLoading = true
        hasSearched = true
        suggestions = []

        let params: [String: Any] = ["query": query.trim]
        let headers = UserDefaultManager.shared.authHeader

        service.search(params: params, headers: headers)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
            } receiveValue: { [weak self] response in
                self?.products = response.products ?? []
            }
            .store(in: &cancellables)
    }
}

#Preview {
    NavigationStack {
        SearchScreen()
    }
}
