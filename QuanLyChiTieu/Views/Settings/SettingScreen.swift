import SwiftUI
import UserNotifications

struct SettingsRowView: View {
    var iconName: String
    var title: LocalizedStringKey
    var tintColor: Color
    var showChevron: Bool = true
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            // Icon với circle background giống TransactionRow
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(tintColor)
                .frame(width: 44, height: 44)
                .background(tintColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 4)
        )
        .contentShape(Rectangle())
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
    
    @StateObject private var appearanceSettings = AppearanceSettings.shared
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    @State private var isDailyReminderEnabled: Bool = false
    @State private var reminderTime: Date = Date()
    @State private var isShowingCategoryList: Bool = false
    @State private var isShowingResetAlert = false
    
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
        NavigationStack(path: navigationCoordinator.path(for: 5)) {
            AppColors.groupedBackground
                .ignoresSafeArea()
                .overlay(
                    ScrollView {
                        VStack(spacing: 18) {
                            // MARK: - General Settings
                            VStack(alignment: .leading, spacing: 12) {
                                Text("settings_section_general")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    NavigationLink(destination: LanguageSelectionView()) {
                                        SettingsRowView(iconName: "globe", title: "settings_row_language", tintColor: .blue)
                                    }
                                    
                                    // Appearance Picker - Card riêng
                                    HStack(spacing: 16) {
                                        Image(systemName: "paintbrush")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.purple)
                                            .frame(width: 44, height: 44)
                                            .background(Color.purple.opacity(0.15))
                                            .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("settings_row_appearance")
                                                .font(.system(.headline, design: .rounded))
                                                .foregroundColor(.primary)
                                            
                                            Text(appearanceSettings.currentAppearance.localizedName)
                                                .font(.system(.subheadline, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Picker("", selection: Binding(
                                            get: { appearanceSettings.currentAppearance },
                                            set: { appearanceSettings.selectedAppearance = $0.rawValue }
                                        )) {
                                            ForEach(AppearanceMode.allCases) { mode in
                                                Text(mode.localizedName).tag(mode)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                    }
                                    .padding(15)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(AppColors.cardBackground)
                                            .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 4)
                                    )
                                    
                                    NavigationLink(destination: CurrencySelectionView()) {
                                        SettingsRowView(
                                            iconName: "dollarsign.circle", 
                                            title: "settings_row_currency", 
                                            tintColor: AppColors.incomeColor,
                                            subtitle: CurrencySettings.shared.currentCurrency.symbol
                                        )
                                    }
                                    
                                    NavigationLink(destination: StartOfWeekView()) {
                                        SettingsRowView(iconName: "calendar", title: "settings_row_week_start", tintColor: .orange)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // MARK: - Savings Goals & Budgets
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Mục tiêu tiết kiệm")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                NavigationLink(destination: SavingsGoalsScreen()) {
                                    SettingsRowView(iconName: "target", title: "Quản lý mục tiêu", tintColor: AppColors.primaryButton)
                                }
                                .padding(.horizontal)
                                
                                NavigationLink(destination: BudgetsScreen()) {
                                    SettingsRowView(iconName: "chart.bar.fill", title: "Ngân sách", tintColor: .orange)
                                }
                                .padding(.horizontal)
                                
                                NavigationLink(destination: RecurringTransactionsScreen()) {
                                    SettingsRowView(iconName: "repeat.circle.fill", title: "settings_row_recurring_transactions", tintColor: .purple)
                                }
                                .padding(.horizontal)
                            }
                            
                            // MARK: - Data Management
                            VStack(alignment: .leading, spacing: 12) {
                                Text("settings_section_data")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
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
                                .padding(.horizontal)
                            }
                            
                            // MARK: - Security
                            VStack(alignment: .leading, spacing: 12) {
                                Text("settings_section_security")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    Toggle(isOn: appLockBinding) {
                                        SettingsRowView(iconName: "lock.shield", title: "settings_row_app_lock_pin", tintColor: AppColors.expenseColor, showChevron: false)
                                    }
                                    
                                    if authManager.isAppLockEnabled {
                                        Toggle(isOn: faceIDBinding) {
                                            SettingsRowView(iconName: "faceid", title: "settings_row_use_faceid", tintColor: .blue, showChevron: false)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // MARK: - Notifications
                            VStack(alignment: .leading, spacing: 12) {
                                Text("settings_section_notifications")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    Toggle(isOn: $isDailyReminderEnabled) {
                                        SettingsRowView(iconName: "bell.badge", title: "settings_row_daily_reminder", tintColor: .teal, showChevron: false)
                                    }
                                    
                                    if isDailyReminderEnabled {
                                        DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                                            SettingsRowView(iconName: "clock", title: "settings_row_reminder_time", tintColor: .teal, showChevron: false)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // MARK: - About
                            VStack(alignment: .leading, spacing: 12) {
                                Text("settings_section_about")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    Link(destination: URL(string: "https://www.apple.com/app-store/")!) {
                                        SettingsRowView(iconName: "star.fill", title: "settings_row_rate_app", tintColor: .yellow)
                                    }
                                    .foregroundColor(.primary)
                                    
                                    Link(destination: URL(string: "mailto:support@example.com")!) {
                                        SettingsRowView(iconName: "envelope.fill", title: "settings_row_feedback", tintColor: .mint)
                                    }
                                    .foregroundColor(.primary)
                                    
                                    NavigationLink(destination: PrivacyPolicyView()) {
                                        SettingsRowView(iconName: "hand.raised.fill", title: "settings_row_privacy_policy", tintColor: .gray)
                                    }
                                    
                                    HStack(spacing: 16) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.gray)
                                            .frame(width: 44, height: 44)
                                            .background(Color.gray.opacity(0.15))
                                            .clipShape(Circle())
                                        
                                        Text("settings_row_version")
                                            .font(.system(.headline, design: .rounded))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        Text("1.0.0")
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(15)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(AppColors.cardBackground)
                                            .shadow(color: AppColors.cardShadow, radius: 8, x: 0, y: 4)
                                    )
                                }
                                .padding(.horizontal)
                            }
                            
                            // MARK: - Danger Zone
                            VStack(alignment: .leading, spacing: 12) {
                                Text("settings_section_danger")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    isShowingResetAlert = true
                                }) {
                                    SettingsRowView(iconName: "trash.fill", title: "settings_row_reset_data", tintColor: AppColors.expenseColor)
                                        .foregroundColor(AppColors.expenseColor)
                                }
                                .padding(.horizontal)
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.top, 70)
                    }
                )
            .navigationBarHidden(true)
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
            // Custom Navigation Bar
            .overlay(
                GeometryReader { geometry in
                    VStack {
                        HStack {
                            Spacer()
                            Text("settings_title")
                                .font(.custom("Bungee-Regular", size: 32))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top - 15 : 35)
                        .background(AppColors.groupedBackground)
                        Spacer()
                    }
                }
            )
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
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PopToRoot"))) { notification in
                if let tab = notification.userInfo?["tab"] as? Int, tab == 5 {
                    // Pop về root bằng cách clear path
                    navigationCoordinator.popToRoot(for: 5)
                }
            }
        }
    }
}

// MARK: - Currency Selection View
struct CurrencySelectionView: View {
    @StateObject private var currencySettings = CurrencySettings.shared
    @Environment(\.dismiss) var dismiss
    
    private let currencies: [(currency: Currency, symbol: String, description: String)] = [
        (.vnd, "₫", "Đồng Việt Nam"),
        (.usd, "$", "US Dollar")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(currencies, id: \.currency.id) { item in
                    CurrencyRowView(
                        currency: item.currency,
                        symbol: item.symbol,
                        description: item.description,
                        isSelected: currencySettings.currentCurrency == item.currency
                    ) {
                        currencySettings.selectedCurrency = item.currency.rawValue
                        dismiss()
                    }
                }
            }
            .padding()
        }
        .background(AppColors.groupedBackground.ignoresSafeArea())
        .navigationTitle(Text("settings_row_currency"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CurrencyRowView: View {
    let currency: Currency
    let symbol: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Symbol với background đẹp
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppColors.incomeColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Text(symbol)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.incomeColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currency.localizedName)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.primaryButton)
                }
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.primaryButton : Color.clear, lineWidth: 2)
            )
            .shadow(color: AppColors.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Start of Week View
struct StartOfWeekView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Tính năng này sẽ được phát triển trong tương lai")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
        .background(AppColors.groupedBackground.ignoresSafeArea())
        .navigationTitle(Text("settings_row_week_start"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Change Passcode View
struct ChangePasscodeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Tính năng này sẽ được phát triển trong tương lai")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
        }
        .background(AppColors.groupedBackground.ignoresSafeArea())
        .navigationTitle(Text("settings_row_change_passcode"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Privacy Policy View
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Chính sách Quyền riêng tư")
                    .font(.system(.title2, design: .rounded).bold())
                    .padding(.bottom, 8)
                
                Text("Nội dung chính sách quyền riêng tư sẽ được cập nhật tại đây.")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(AppColors.groupedBackground.ignoresSafeArea())
        .navigationTitle(Text("settings_row_privacy_policy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
