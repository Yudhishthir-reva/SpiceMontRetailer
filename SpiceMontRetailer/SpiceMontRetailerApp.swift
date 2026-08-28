//
//  SpiceMontRetailerApp.swift
//  SpiceMontRetailer
//
//  Created by Reva on 23/08/26.
//

import SwiftUI

@main
struct SpiceMontRetailerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            SplashScreen()
                .font(.dmSans(14, weight: .regular))
                .preferredColorScheme(.light)
                .handleNoInternet()
                .handleAppStatusOverlays()
                .onAppear {
                    UIApplication.shared.addTapGestureToDismissKeyboard()
                    AppConfigManager.shared.checkStatus()
                }
        }
    }
}

