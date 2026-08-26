//
//  MainTabView.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeScreen()
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("HOME")
            }
            .tag(0)

            NavigationStack {
                BrandSelectionScreen()
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "square.grid.2x2.fill" : "square.grid.2x2")
                Text("CATEGORIES")
            }
            .tag(1)

            NavigationStack {
                OrdersScreen()
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "list.bullet.clipboard.fill" : "list.bullet.clipboard")
                Text("ORDERS")
            }
            .tag(2)

            NavigationStack {
                LedgerScreen()
            }
            .tabItem {
                Image(systemName: selectedTab == 3 ? "doc.plaintext.fill" : "doc.plaintext")
                Text("LEDGER")
            }
            .tag(3)

            NavigationStack {
                PaymentsScreen()
            }
            .tabItem {
                Image(systemName: selectedTab == 4 ? "creditcard.fill" : "creditcard")
                Text("PAYMENTS")
            }
            .tag(4)
        }
        .tint(Color.spicePrimary)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            appearance.shadowColor = UIColor(hex: "#EEF0EC")

            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

#Preview {
    MainTabView()
}
