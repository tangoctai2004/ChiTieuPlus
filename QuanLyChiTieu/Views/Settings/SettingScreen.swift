import SwiftUI
import UserNotifications

struct SettingsRowView: View {
    // (Struct này giữ nguyên, không đổi)
    var iconName: String
    var title: LocalizedStringKey
    var tintColor: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.headline)
                .foregroundColor(tintColor)
                .frame(width: 25, height: 25, alignment: .center)
                .background(tintColor.opacity(0.1))
                .cornerRadius(6)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct SettingScreen: View {
    
    @EnvironmentObject var authManager: LocalAuthManager
    
    // State để mở màn hình tạo PIN
    @State private var isShowingSetPasscodeView = false
    
    // --- THÊM MỚI 2 STATE CHO ALERT ---
    @State private var isShowingPasscodeWarningAlert = false // Cảnh báo khi Bật
    @State private var isShowingDisableLockAlert = false // Cảnh báo khi Tắt
    // --- KẾT THÚC THÊM MỚI ---
    
    @State private var isDailyReminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var appearance: AppearanceMode = .system
    @State private var isShowingCategoryList: Bool = false
    @State private var isShowingResetAlert = false
    
    // (Enum AppearanceMode giữ nguyên)
    enum AppearanceMode: String, CaseIterable, Identifiable {
        case light = "settings_appearance_light"
        case dark = "settings_appearance_dark"
        case system = "settings_appearance_system"
        var id: Self { self }
        
        var localizedName: LocalizedStringKey {
            return LocalizedStringKey(self.rawValue)
        }
    }
    
    // --- SỬA ĐỔI BINDING NÀY ---
    // Binding tùy chỉnh cho Toggle "Khóa ứng dụng"
    private var appLockBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                return self.authManager.isAppLockEnabled
            },
            set: { wantsToEnable in
                if wantsToEnable {
                    // Nếu gạt BẬT -> Hiển thị cảnh báo "Quên mật khẩu"
                    self.isShowingPasscodeWarningAlert = true
                } else {
                    // Nếu gạt TẮT -> Hiển thị cảnh báo "Xác nhận tắt"
                    self.isShowingDisableLockAlert = true
                }
            }
        )
    }
    // --- KẾT THÚC SỬA ĐỔI ---
    
    // Binding tùy chỉnh cho Toggle "Face ID" (giữ nguyên)
    private var faceIDBinding: Binding<Bool> {
        Binding<Bool>(
            get: {
                return self.authManager.isFaceIDEnabled
            },
            set: { _ in
                self.authManager.toggleFaceIDSetting()
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                // (Các Section "general", "data" giữ nguyên)
                Section(header: Text("settings_section_general")) {
                    NavigationLink(destination: LanguageSelectionView()) {
                        SettingsRowView(iconName: "globe", title: "settings_row_language", tintColor: .blue)
                    }
                    Picker(selection: $appearance, label: SettingsRowView(iconName: "paintbrush", title: "settings_row_appearance", tintColor: .purple)) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    NavigationLink(destination: CurrencySelectionView()) {
                        SettingsRowView(iconName: "dollarsign.circle", title: "settings_row_currency", tintColor: .green)
                    }
                    NavigationLink(destination: StartOfWeekView()) {
                        SettingsRowView(iconName: "calendar", title: "settings_row_week_start", tintColor: .orange)
                    }
                }
                Section(header: Text("settings_section_data")) {
                    Button(action: {
                        isShowingCategoryList = true
                    }) {
                        SettingsRowView(iconName: "list.bullet.rectangle.portrait", title: "settings_row_manage_categories", tintColor: .cyan)
                    }
                    .foregroundColor(.primary)
                    NavigationLink(destination: BackupRestoreScreen()) {
                        SettingsRowView(iconName: "arrow.up.doc", title: "settings_row_export_data", tintColor: .gray)
                    }
                }

                // (Section Security giữ nguyên)
                Section(header: Text("settings_section_security")) {
                    // 1. Toggle "Khóa ứng dụng" (dùng PIN)
                    Toggle(isOn: appLockBinding) {
                        SettingsRowView(iconName: "lock.shield", title: "settings_row_app_lock_pin", tintColor: .red)
                    }
                    
                    // 2. Toggle "Sử dụng Face ID"
                    if authManager.isAppLockEnabled {
                        Toggle(isOn: faceIDBinding) {
                            SettingsRowView(iconName: "faceid", title: "settings_row_use_faceid", tintColor: .blue)
                        }
                    }
                }

                // (Các Section "notifications", "about", "danger" giữ nguyên)
                Section(header: Text("settings_section_notifications")) {
                    Toggle(isOn: $isDailyReminderEnabled) {
                        SettingsRowView(iconName: "bell.badge", title: "settings_row_daily_reminder", tintColor: .teal)
                    }
                    if isDailyReminderEnabled {
                        DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                            SettingsRowView(iconName: "clock", title: "settings_row_reminder_time", tintColor: .teal)
                        }
                    }
                }
                Section(header: Text("settings_section_about")) {
                    Link(destination: URL(string: "https://www.apple.com/app-store/")!) {
                        SettingsRowView(iconName: "star", title: "settings_row_rate_app", tintColor: .yellow)
                    }
                    .foregroundColor(.primary)
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        SettingsRowView(iconName: "bubble.left.and.bubble.right", title: "settings_row_feedback", tintColor: .mint)
                    }
                    .foregroundColor(.primary)
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRowView(iconName: "hand.raised", title: "settings_row_privacy_policy", tintColor: .gray)
                    }
                    HStack {
                        SettingsRowView(iconName: "info.circle", title: "settings_row_version", tintColor: .gray)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                Section(header: Text("settings_section_danger")) {
                    Button(action: {
                        isShowingResetAlert = true
                    }) {
                        SettingsRowView(iconName: "trash", title: "settings_row_reset_data", tintColor: .red)
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(Text("settings_title"))
            .sheet(isPresented: $isShowingCategoryList) {
                NavigationStack {
                    CategoryListScreen()
                }
            }
            .sheet(isPresented: $isShowingSetPasscodeView) {
                NavigationStack {
                    SetPasscodeView(
                        isPresented: $isShowingSetPasscodeView,
                        authManager: authManager
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                    }) {
                        Text("settings_help")
                    }
                }
            }
            // (Alert "Reset Dữ liệu" giữ nguyên)
            .alert(Text("alert_delete_confirmation_title"), isPresented: $isShowingResetAlert) {
                Button(role: .destructive) {
                    DataRepository.shared.resetAllData()
                } label: {
                    Text("alert_button_confirm_delete")
                }
                Button(role: .cancel) { } label: {
                    Text("alert_button_cancel")
                }
            } message: {
                Text("alert_reset_all_data_message")
            }
            
            // --- THÊM MỚI 2 ALERT CHO MÃ PIN ---
            .alert(
                "Lưu ý quan trọng", // Tiêu đề Alert
                isPresented: $isShowingPasscodeWarningAlert
            ) {
                Button("Hủy", role: .cancel) {
                    // Người dùng nhấn Hủy, không làm gì cả
                }
                Button("Tôi đã hiểu, tiếp tục") {
                    // Người dùng đồng ý, mở màn hình tạo PIN
                    isShowingSetPasscodeView = true
                }
            } message: {
                // Nội dung cảnh báo (theo yêu cầu của bạn)
                Text("Nếu bạn quên mã PIN, bạn sẽ phải reset toàn bộ dữ liệu ứng dụng. Hành động này không thể hoàn tác.")
            }
            .alert(
                "Tắt khóa ứng dụng?", // Tiêu đề Alert
                isPresented: $isShowingDisableLockAlert
            ) {
                Button("Hủy", role: .cancel) {
                    // Người dùng nhấn Hủy, không tắt
                }
                Button("Tắt khóa", role: .destructive) {
                    // Người dùng đồng ý Tắt, gọi hàm xóa PIN
                    authManager.disableAppLock()
                }
            } message: {
                Text("Việc này sẽ xóa mã PIN của bạn và tắt Face ID. Ứng dụng sẽ không còn được bảo vệ.")
            }
            // --- KẾT THÚC THÊM MỚI ---

            // (Modifier cho Thông báo giữ nguyên)
            .onAppear {
                NotificationManager.shared.requestPermission()
                self.isDailyReminderEnabled = NotificationManager.shared.isReminderEnabled()
                if let savedTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date {
                    self.reminderTime = savedTime
                }
            }
            .onChange(of: isDailyReminderEnabled) { enabled in
                NotificationManager.shared.handleReminderToggle(isOn: enabled, at: reminderTime)
            }
            .onChange(of: reminderTime) { newTime in
                if isDailyReminderEnabled {
                    NotificationManager.shared.handleReminderToggle(isOn: true, at: newTime)
                }
            }
        }
    }
}

// (Các Struct View khác giữ nguyên)
struct CurrencySelectionView: View {
    var body: some View { Text("Chọn Tiền tệ").navigationTitle(Text("settings_row_currency")) }
}
struct StartOfWeekView: View {
    var body: some View { Text("Chọn Ngày bắt đầu tuần").navigationTitle(Text("settings_row_week_start")) }
}
struct ChangePasscodeView: View {
    var body: some View { Text("Thay đổi mật khẩu").navigationTitle(Text("settings_row_change_passcode")) }
}
struct PrivacyPolicyView: View {
    var body: some View { Text("Nội dung Chính sách Quyền riêng tư").navigationTitle(Text("settings_row_privacy_policy")) }
}
