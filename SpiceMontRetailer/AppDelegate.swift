//
//  AppDelegate.swift
//  SpiceMonk
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AppFont.registerFontsIfNeeded()
        UIView.appearance().overrideUserInterfaceStyle = .light

        // Configure Firebase
        FirebaseApp.configure()
        print("🔥 [Firebase] FirebaseApp configured successfully.")

        Messaging.messaging().delegate = self

        registerForPushNotifications()
        NetworkMonitor.shared.start()
        AuthSessionManager.shared.start()
        UIApplication.shared.addTapGestureToDismissKeyboard()

        return true
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if let error = error {
                    print("❌ [Notification] Authorization error: \(error.localizedDescription)")
                } else {
                    print("🔔 [Notification] Push notification permission granted: \(granted)")
                    if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            }
        )
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("📱 [APNs] APNs Device Token: \(tokenString)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ [APNs] Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("📩 [Notification] User tapped notification with userInfo: \(userInfo)")
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("==================================================")
        print("🔥 [Firebase] FCM Registration Token:")
        print(fcmToken ?? "No token found")
        print("==================================================")

        if let token = fcmToken, !token.isEmpty {
            UserDefaultManager.shared.setUserDefaultsString(value: token, key: .fcmToken)
        }
    }
}
