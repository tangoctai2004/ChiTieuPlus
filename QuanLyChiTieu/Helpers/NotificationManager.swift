import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private let dailyReminderIdentifier = "daily_transaction_reminder"
    private let reminderTimeKey = "reminderTime"
    private let reminderEnabledKey = "reminderEnabled"
    
    // --- HÀM CÔNG CỤ ---
    
    /// 1. Xin quyền
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification Permission Granted")
            } else if let error = error {
                print("Notification Permission Error: \(error.localizedDescription)")
            }
        }
    }
    
    /// 2. Hủy tất cả thông báo
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        UserDefaults.standard.set(false, forKey: reminderEnabledKey)
        print("Đã hủy và tắt tất cả thông báo")
    }
    
    /// 3. Lên lịch (Hàm cốt lõi)
    /// Lên lịch cho 1 ngày cụ thể (vd: "hôm nay" hoặc "ngày mai")
    func scheduleReminder(for date: Date) {
        // 1. Lấy giờ và phút đã lưu
        guard let savedTime = getReminderTime() else {
             print("Lên lịch thất bại: không tìm thấy giờ đã lưu")
             return
        }
        
        let center = UNUserNotificationCenter.current()
        
        // 2. Hủy lịch cũ (nếu có)
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        
        // 3. Tạo nội dung
        let content = UNMutableNotificationContent()
        content.title = "Sổ thu chi"
        content.body = "Bạn có quên nhập vào ngày hôm nay không?"
        content.sound = .default
        content.userInfo = ["action": "addTransaction"]
        
        // 4. Tạo trigger
        // Lấy (giờ, phút) từ savedTime và (ngày, tháng, năm) từ 'date'
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: savedTime)
        let minute = calendar.component(.minute, from: savedTime)
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Quan trọng: Phải là non-repeating
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: dailyReminderIdentifier, content: content, trigger: trigger)
        
        // 5. Thêm lịch
        center.add(request) { error in
            if let error = error {
                print("Lỗi lên lịch: \(error.localizedDescription)")
            } else {
                print("ĐÃ LÊN LỊCH: Thông báo cho \(dateComponents.day ?? 0)/\(dateComponents.month ?? 0) lúc \(hour):\(minute)")
            }
        }
    }
    
    // --- CÁC HÀM XỬ LÝ SỰ KIỆN ---
    
    /// 4. Gọi khi bật/thay đổi giờ trong SettingScreen
    func handleReminderToggle(isOn: Bool, at time: Date) {
        saveReminderTime(time)
        UserDefaults.standard.set(isOn, forKey: reminderEnabledKey)
        
        if isOn {
            // Lên lịch cho HÔM NAY
            scheduleReminder(for: Date())
        } else {
            cancelAllReminders()
        }
    }
    
    /// 5. Gọi khi người dùng LƯU giao dịch
    func handleSuccessfulSave() {
        guard isReminderEnabled() else { return } // Nếu người dùng tắt thì thôi
        
        // 1. Hủy thông báo của hôm nay
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        print("Đã hủy thông báo hôm nay (vì đã nhập).")

        // 2. Lên lịch cho NGÀY MAI
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
            scheduleReminder(for: tomorrow)
        }
    }
    
    /// 6. Gọi khi App KHỞI ĐỘNG
    func handleAppLaunch() {
        guard isReminderEnabled() else { return }
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Nếu không có thông báo nào đang chờ
            if requests.first(where: { $0.identifier == self.dailyReminderIdentifier }) == nil {
                // Có nghĩa là đã qua 9h tối hôm qua, và chưa có lịch cho hôm nay
                // -> Lên lịch cho HÔM NAY
                print("App khởi động, không thấy lịch, đang lên lịch cho hôm nay.")
                self.scheduleReminder(for: Date())
            }
        }
    }
    
    // --- HÀM HỖ TRỢ (Lưu/Đọc giờ) ---
    private func saveReminderTime(_ time: Date) {
        UserDefaults.standard.set(time, forKey: reminderTimeKey)
    }
    
    private func getReminderTime() -> Date? {
        return UserDefaults.standard.object(forKey: reminderTimeKey) as? Date
    }
    
    func isReminderEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: reminderEnabledKey)
    }
}
