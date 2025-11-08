import UIKit
import UserNotifications // <-- THÊM MỚI

// --- THÊM MỚI ---
extension Notification.Name {
    static let didTapDailyReminder = Notification.Name("didTapDailyReminder")
}
// --- KẾT THÚC THÊM MỚI ---

// --- SỬA ĐỔI ---
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    static var orientationLock = UIInterfaceOrientationMask.portrait

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
    
    // --- THÊM MỚI ---
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        // Khi app khởi động, gọi hàm kiểm tra và lên lịch
        NotificationManager.shared.handleAppLaunch()
        
        return true
    }
    
    // Xử lý khi app đang chạy
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .banner, .badge])
    }
    
    // Xử lý khi nhấn vào thông báo
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        if userInfo["action"] as? String == "addTransaction" {
            NotificationCenter.default.post(name: .didTapDailyReminder, object: nil)
        }
        completionHandler()
    }
    // --- KẾT THÚC THÊM MỚI ---
}
