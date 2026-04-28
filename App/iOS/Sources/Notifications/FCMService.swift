import FirebaseMessaging
import Foundation
import UIKit

final class FCMService: NSObject {
    static let shared = FCMService()

    private override init() {}

    func start() {
        Messaging.messaging().delegate = self
    }

    func setAPNSToken(_ token: Data) {
        Messaging.messaging().apnsToken = token
        print("[FCM] APNs token registered")

        Task {
            _ = await currentToken()
        }
    }

    func currentToken() async -> String? {
        do {
            let token = try await Messaging.messaging().token()
            print("[FCM] current token: \(token)")
            return token
        } catch {
            print("[FCM] token fetch failed: \(error)")
            return nil
        }
    }
}

extension FCMService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        print("[FCM] registration token refreshed: \(fcmToken)")

        NotificationCenter.default.post(
            name: .fcmTokenRefreshed,
            object: nil,
            userInfo: ["token": fcmToken]
        )
    }
}

extension Notification.Name {
    static let fcmTokenRefreshed = Notification.Name("fcmTokenRefreshed")
}
