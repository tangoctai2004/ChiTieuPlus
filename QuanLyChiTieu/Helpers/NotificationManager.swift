import Foundation
import UserNotifications
import CoreData

class NotificationManager {
    static let shared = NotificationManager()
    private let dailyReminderIdentifier = "daily_transaction_reminder"
    private let reminderTimeKey = "reminderTime"
    private let reminderEnabledKey = "reminderEnabled"
    
    // --- HÀM CÔNG CỤ ---
    
//    1. Xin quyền
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Notification Permission Granted")
            } else if let error = error {
                print("❌ Notification Permission Error: \(error.localizedDescription)")
            } else {
                print("⚠️ Notification Permission Denied")
            }
        }
    }
    
//     Kiểm tra quyền thông báo
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("📱 Notification Settings:")
            print("   - Authorization Status: \(settings.authorizationStatus.rawValue)")
            print("   - Alert Setting: \(settings.alertSetting.rawValue)")
            print("   - Sound Setting: \(settings.soundSetting.rawValue)")
            print("   - Badge Setting: \(settings.badgeSetting.rawValue)")
        }
    }
    
//     In ra tất cả thông báo đang chờ
    func printAllPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Tổng số thông báo đang chờ: \(requests.count)")
            for request in requests {
                if request.identifier.contains("savings_goal") {
                    print("   - \(request.identifier)")
                    print("     Title: \(request.content.title)")
                    print("     Body: \(request.content.body)")
                    if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                        print("     Date: \(trigger.dateComponents)")
                    } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                        print("     TimeInterval: \(trigger.timeInterval) giây")
                    }
                }
            }
        }
    }
    
//     2. Hủy tất cả thông báo
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        UserDefaults.standard.set(false, forKey: reminderEnabledKey)
        print("Đã hủy và tắt tất cả thông báo")
    }
    
//     3. Lên lịch (Hàm cốt lõi)
//     Lên lịch cho 1 ngày cụ thể (vd: "hôm nay" hoặc "ngày mai")
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
    
//     4. Gọi khi bật/thay đổi giờ trong SettingScreen
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
    
//    5. Gọi khi người dùng LƯU giao dịch
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
    
//     6. Gọi khi App KHỞI ĐỘNG
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
    
    // MARK: - Savings Goal Completion Notification
    
//     Gửi thông báo khi mục tiêu tiết kiệm đạt 100%
    func sendSavingsGoalCompletionNotification(goalTitle: String) {
        let center = UNUserNotificationCenter.current()
        
        // Tạo nội dung thông báo
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("savings_goal_completed_notification_title", comment: "")
        content.body = String(format: NSLocalizedString("savings_goal_completed_notification_body", comment: ""), goalTitle)
        content.sound = .default
        content.userInfo = ["action": "savingsGoalCompleted", "goalTitle": goalTitle]
        
        // Gửi thông báo ngay lập tức
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "savings_goal_completed_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Lỗi khi gửi thông báo hoàn thành mục tiêu: \(error.localizedDescription)")
            } else {
                print("✅ Đã gửi thông báo hoàn thành mục tiêu: \(goalTitle)")
            }
        }
    }
    
    // MARK: - Savings Goal Expiration Notifications
    
//     Lên lịch thông báo cho mục tiêu sắp hết hạn
    func scheduleSavingsGoalExpirationNotifications(for goal: SavingsGoal) {
        guard let targetDate = goal.targetDate,
              let goalTitle = goal.title,
              !goal.isCompleted else {
            print("⚠️ Không thể lên lịch thông báo: targetDate hoặc goalTitle nil, hoặc đã hoàn thành")
            return
        }
        
        print("📅 Bắt đầu lên lịch thông báo cho mục tiêu: \(goalTitle)")
        print("   - Ngày hết hạn: \(targetDate)")
        
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: targetDate)
        
        // Tính số ngày còn lại
        guard let daysRemaining = calendar.dateComponents([.day], from: today, to: target).day else {
            print("⚠️ Không thể tính daysRemaining")
            return
        }
        
        print("   - Số ngày còn lại: \(daysRemaining)")
        
        // Hủy các thông báo cũ của mục tiêu này
        let goalId = goal.id?.uuidString ?? UUID().uuidString
        center.removePendingNotificationRequests(withIdentifiers: [
            "savings_goal_expiring_7_\(goalId)",
            "savings_goal_expiring_3_\(goalId)",
            "savings_goal_expiring_1_\(goalId)",
            "savings_goal_expired_\(goalId)"
        ])
        
        // Thông báo 7 ngày trước
        if daysRemaining >= 7 {
            if let date7Days = calendar.date(byAdding: .day, value: -7, to: target) {
                print("   📢 Lên lịch thông báo 7 ngày: \(date7Days)")
                scheduleExpirationNotification(
                    identifier: "savings_goal_expiring_7_\(goalId)",
                    title: NSLocalizedString("savings_goal_expiring_7_days_title", comment: ""),
                    body: String(format: NSLocalizedString("savings_goal_expiring_7_days_body", comment: ""), goalTitle),
                    date: date7Days
                )
            }
        }
        
        // Thông báo 3 ngày trước
        if daysRemaining >= 3 {
            if let date3Days = calendar.date(byAdding: .day, value: -3, to: target) {
                print("   📢 Lên lịch thông báo 3 ngày: \(date3Days)")
                scheduleExpirationNotification(
                    identifier: "savings_goal_expiring_3_\(goalId)",
                    title: NSLocalizedString("savings_goal_expiring_3_days_title", comment: ""),
                    body: String(format: NSLocalizedString("savings_goal_expiring_3_days_body", comment: ""), goalTitle),
                    date: date3Days
                )
            }
        }
        
        // Thông báo 1 ngày trước
        if daysRemaining >= 1 {
            if let date1Day = calendar.date(byAdding: .day, value: -1, to: target) {
                print("   📢 Lên lịch thông báo 1 ngày: \(date1Day)")
                scheduleExpirationNotification(
                    identifier: "savings_goal_expiring_1_\(goalId)",
                    title: NSLocalizedString("savings_goal_expiring_1_day_title", comment: ""),
                    body: String(format: NSLocalizedString("savings_goal_expiring_1_day_body", comment: ""), goalTitle),
                    date: date1Day
                )
            }
        }
        
        // Thông báo khi đã hết hạn hoặc hôm nay là hạn chót
        if daysRemaining <= 0 {
            print("   ⚠️ Mục tiêu đã hết hạn hoặc hôm nay là hạn chót (daysRemaining: \(daysRemaining))")
            // Nếu hôm nay là hạn chót (daysRemaining = 0), lên lịch vào 9:00 sáng
            if daysRemaining == 0 {
                print("   📢 Hôm nay là hạn chót, lên lịch vào 9:00 sáng")
                let calendar = Calendar.current
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
                dateComponents.hour = 9
                dateComponents.minute = 0
                
                // Nếu giờ đã qua (đã qua 9:00 sáng hôm nay), gửi ngay lập tức
                if let scheduledDate = calendar.date(from: dateComponents),
                   scheduledDate < Date() {
                    print("   ✅ Đã qua 9:00 sáng, gửi thông báo ngay lập tức")
                    sendExpiredNotification(
                        identifier: "savings_goal_expired_\(goalId)",
                        title: NSLocalizedString("savings_goal_expired_notification_title", comment: ""),
                        body: String(format: NSLocalizedString("savings_goal_expired_notification_body", comment: ""), goalTitle)
                    )
                } else {
                    // Lên lịch vào 9:00 sáng
                    print("   📅 Lên lịch thông báo vào 9:00 sáng")
                    scheduleExpirationNotification(
                        identifier: "savings_goal_expired_\(goalId)",
                        title: NSLocalizedString("savings_goal_expired_notification_title", comment: ""),
                        body: String(format: NSLocalizedString("savings_goal_expired_notification_body", comment: ""), goalTitle),
                        date: targetDate
                    )
                }
            } else {
                // Đã quá hạn (daysRemaining < 0), gửi ngay lập tức
                print("   ✅ Đã quá hạn, gửi thông báo ngay lập tức")
                sendExpiredNotification(
                    identifier: "savings_goal_expired_\(goalId)",
                    title: NSLocalizedString("savings_goal_expired_notification_title", comment: ""),
                    body: String(format: NSLocalizedString("savings_goal_expired_notification_body", comment: ""), goalTitle)
                )
            }
        }
    }
    
    private func scheduleExpirationNotification(identifier: String, title: String, body: String, date: Date) {
        print("   🔔 scheduleExpirationNotification: \(identifier)")
        print("      - Title: \(title)")
        print("      - Body: \(body)")
        print("      - Date: \(date)")
        
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        // Luôn dùng 9:00 sáng cho thông báo mục tiêu tiết kiệm
        let hour = 9
        let minute = 0
        print("      - Sử dụng giờ cố định: 9:00")
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["action": "savingsGoalExpiring", "identifier": identifier]
        
        // Nếu thời gian đã qua, gửi ngay lập tức (để test)
        if let scheduledDate = calendar.date(from: dateComponents) {
            print("      - Thời gian lên lịch: \(scheduledDate)")
            print("      - Thời gian hiện tại: \(Date())")
            
            if scheduledDate < Date() {
                print("      ✅ Thời gian đã qua, gửi thông báo sau 2 giây")
                // Gửi sau 2 giây để test
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("      ❌ Lỗi khi gửi thông báo: \(error.localizedDescription)")
                    } else {
                        print("      ✅ Đã gửi thông báo ngay (thời gian đã qua): \(identifier)")
                    }
                }
                return
            }
        }
        
        // Lên lịch thông báo
        print("      📅 Lên lịch thông báo vào \(hour):\(String(format: "%02d", minute))")
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("      ❌ Lỗi khi lên lịch thông báo: \(error.localizedDescription)")
            } else {
                print("      ✅ Đã lên lịch thông báo: \(identifier) lúc \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    private func sendExpiredNotification(identifier: String, title: String, body: String) {
        print("   🔔 sendExpiredNotification: \(identifier)")
        print("      - Title: \(title)")
        print("      - Body: \(body)")
        
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["action": "savingsGoalExpired", "identifier": identifier]
        
        // Gửi thông báo ngay lập tức (sau 1 giây để đảm bảo)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("      ❌ Lỗi khi gửi thông báo hết hạn: \(error.localizedDescription)")
            } else {
                print("      ✅ Đã gửi thông báo hết hạn: \(identifier) (sau 1 giây)")
            }
        }
    }
    
    // MARK: - Budget Notifications
    
//    Kiểm tra và gửi thông báo khi budget vượt quá các ngưỡng cảnh báo
    func checkAndNotifyBudgetThresholds(for budget: Budget) {
        guard budget.isActive else { return }
        
        let percentage = budget.usagePercentage * 100
        let thresholds = budget.parsedWarningThresholds
        let budgetId = budget.id?.uuidString ?? UUID().uuidString
        
        // Lấy tên category hoặc "Tổng chi tiêu"
        let categoryName: String
        if let categoryID = budget.categoryID {
            if let category = DataRepository.shared.fetchCategory(by: categoryID) {
                // Localize tên category từ key
                categoryName = NSLocalizedString(category.name ?? "common_no_name", comment: "")
            } else {
                categoryName = "Tổng chi tiêu"
            }
        } else {
            categoryName = "Tổng chi tiêu"
        }
        
        // Kiểm tra và gửi thông báo cho từng ngưỡng
        // 80% threshold
        if percentage >= Double(thresholds[0]) && percentage < Double(thresholds[1]) {
            let identifier = "budget_warning_80_\(budgetId)"
            sendBudgetNotification(
                identifier: identifier,
                title: NSLocalizedString("budget_warning_80", comment: ""),
                body: String(format: "Ngân sách \"%@\" đã sử dụng %.0f%%", categoryName, percentage)
            )
        }
        
        // 90% threshold
        if percentage >= Double(thresholds[1]) && percentage < 100 {
            let identifier = "budget_warning_90_\(budgetId)"
            sendBudgetNotification(
                identifier: identifier,
                title: NSLocalizedString("budget_warning_90", comment: ""),
                body: String(format: "Ngân sách \"%@\" đã sử dụng %.0f%%", categoryName, percentage)
            )
        }
        
        // 100% threshold (critical)
        if percentage >= 100 {
            let identifier = "budget_critical_\(budgetId)"
            sendBudgetNotification(
                identifier: identifier,
                title: NSLocalizedString("budget_warning_critical", comment: ""),
                body: String(format: "Ngân sách \"%@\" đã đạt 100%%!", categoryName)
            )
        }
        
        // Vượt quá 100%
        if percentage > 100 {
            let identifier = "budget_exceeded_\(budgetId)"
            let exceededAmount = budget.spentAmount - budget.amount
            sendBudgetNotification(
                identifier: identifier,
                title: NSLocalizedString("budget_warning_exceeded", comment: ""),
                body: String(format: "Ngân sách \"%@\" đã vượt quá %@", categoryName, AppUtils.formattedCurrency(exceededAmount))
            )
        }
    }
    
//     Gửi thông báo budget ngay lập tức
    private func sendBudgetNotification(identifier: String, title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["action": "budgetWarning", "identifier": identifier]
        
        // Gửi sau 1 giây
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ Lỗi khi gửi thông báo budget: \(error.localizedDescription)")
            } else {
                print("✅ Đã gửi thông báo budget: \(identifier)")
            }
        }
    }
    
//     Kiểm tra tất cả budgets và gửi thông báo nếu cần
    func checkAllBudgetsAndNotify() {
        let budgets = DataRepository.shared.fetchBudgets()
        for budget in budgets {
            checkAndNotifyBudgetThresholds(for: budget)
        }
    }
}
