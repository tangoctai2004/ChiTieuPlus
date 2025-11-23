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
    
    // Computed property để chuyển LocalizedStringKey thành String cho subtitle
    private var weekStartSubtitle: String {
        let key: String
        switch WeekStartSettings.shared.currentWeekStartDay {
        case .sunday:
            key = "week_start_sunday"
        case .monday:
            key = "week_start_monday"
        case .tuesday:
            key = "week_start_tuesday"
        case .wednesday:
            key = "week_start_wednesday"
        case .thursday:
            key = "week_start_thursday"
        case .friday:
            key = "week_start_friday"
        case .saturday:
            key = "week_start_saturday"
        }
        return NSLocalizedString(key, comment: "")
    }
    
    var body: some View {
        NavigationStack(path: navigationCoordinator.path(for: 5)) {
            AppColors.groupedBackground
                .ignoresSafeArea()
                .overlay(contentView)
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
                .overlay(customNavigationBar)
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
                .alert("Lưu ý quan trọng", isPresented: $isShowingPasscodeWarningAlert) {
                    Button("Hủy", role: .cancel) { }
                    Button("Tôi đã hiểu, tiếp tục") {
                        isShowingSetPasscodeView = true
                    }
                } message: {
                    Text("Nếu bạn quên mã PIN, bạn sẽ phải reset toàn bộ dữ liệu ứng dụng. Hành động này không thể hoàn tác.")
                }
                .alert("Tắt khóa ứng dụng?", isPresented: $isShowingDisableLockAlert) {
                    Button("Hủy", role: .cancel) { }
                    Button("Tắt khóa", role: .destructive) {
                        authManager.disableAppLock()
                    }
                } message: {
                    Text("Việc này sẽ xóa mã PIN của bạn và tắt Face ID. Ứng dụng sẽ không còn được bảo vệ.")
                }
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
                        navigationCoordinator.popToRoot(for: 5)
                    }
                }
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 18) {
                generalSettingsSection
                savingsGoalsSection
                dataManagementSection
                securitySection
                notificationsSection
                aboutSection
                tutorialSection
                dangerZoneSection
                Spacer(minLength: 20)
            }
            .padding(.top, 70)
        }
    }
    
    // MARK: - Sections
    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings_section_general")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                NavigationLink(destination: LanguageSelectionView()) {
                    SettingsRowView(iconName: "globe", title: "settings_row_language", tintColor: .blue)
                }
                
                appearancePickerCard
                
                NavigationLink(destination: CurrencySelectionView()) {
                    SettingsRowView(
                        iconName: "dollarsign.circle", 
                        title: "settings_row_currency", 
                        tintColor: AppColors.incomeColor,
                        subtitle: CurrencySettings.shared.currentCurrency.symbol
                    )
                }
                
                NavigationLink(destination: StartOfWeekView()) {
                    SettingsRowView(
                        iconName: "calendar",
                        title: "settings_row_week_start",
                        tintColor: .orange,
                        subtitle: weekStartSubtitle
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var appearancePickerCard: some View {
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
    }
    
    private var savingsGoalsSection: some View {
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
    }
    
    private var dataManagementSection: some View {
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
    }
    
    private var securitySection: some View {
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
                    
                    NavigationLink(destination: ChangePasscodeView()) {
                        SettingsRowView(iconName: "key.fill", title: "settings_row_change_passcode", tintColor: .orange)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var notificationsSection: some View {
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
    }
    
    private var aboutSection: some View {
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
                
                versionCard
            }
            .padding(.horizontal)
        }
    }
    
    private var versionCard: some View {
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
    
    private var tutorialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("settings_section_tutorial")
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                TutorialManager.shared.resetTutorial()
            }) {
                SettingsRowView(iconName: "questionmark.circle.fill", title: "settings_row_show_tutorial", tintColor: .blue)
            }
            .foregroundColor(.primary)
            .padding(.horizontal)
        }
    }
    
    private var dangerZoneSection: some View {
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
    }
    
    private var customNavigationBar: some View {
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
        @StateObject private var weekStartSettings = WeekStartSettings.shared
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(WeekStartDay.allCases) { day in
                        WeekStartRowView(
                            day: day,
                            isSelected: weekStartSettings.currentWeekStartDay == day
                        ) {
                            weekStartSettings.weekStartDayRaw = day.rawValue
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .background(AppColors.groupedBackground.ignoresSafeArea())
            .navigationTitle(Text("settings_row_week_start"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    struct WeekStartRowView: View {
        let day: WeekStartDay
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "calendar")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    Text(day.localizedName)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.primary)
                    
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
    
    // MARK: - Change Passcode View
    struct ChangePasscodeView: View {
        @EnvironmentObject var authManager: LocalAuthManager
        @Environment(\.dismiss) var dismiss
        
        enum ChangePasscodeStep {
            case verifyOld
            case createNew
            case confirmNew
        }
        
        @State private var pin: String = ""
        @State private var newPin: String = ""
        @State private var newPinConfirmation: String = ""
        @State private var pinLength: Int = 4
        @State private var currentStep: ChangePasscodeStep = .verifyOld
        @State private var errorMessage: String? = nil
        @State private var isChanging: Bool = false
        
        private var prompt: String {
            switch currentStep {
            case .verifyOld:
                return "Nhập mã PIN hiện tại"
            case .createNew:
                return "Tạo mã PIN mới \(pinLength) số"
            case .confirmNew:
                return "Xác nhận lại mã PIN mới"
            }
        }
        
        var body: some View {
            VStack(spacing: 20) {
                Text(prompt)
                    .font(.headline)
                    .padding(.top, 40)
                
                // Picker chọn 4/6 số (chỉ hiện khi đang tạo mới)
                if currentStep != .verifyOld {
                    Picker("Độ dài mã PIN", selection: $pinLength) {
                        Text("4 Số").tag(4)
                        Text("6 Số").tag(6)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .disabled(currentStep == .confirmNew)
                }
                
                // Hiển thị các dấu chấm
                Group {
                    if currentStep == .verifyOld {
                        ChangePasscodeIndicator(pin: $pin, pinLength: pinLength)
                    } else if currentStep == .createNew {
                        ChangePasscodeIndicator(pin: $newPin, pinLength: pinLength)
                    } else {
                        ChangePasscodeIndicator(pin: $newPinConfirmation, pinLength: pinLength)
                    }
                }
                
                // Hiển thị lỗi
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Bàn phím số
                Group {
                    if currentStep == .verifyOld {
                        ChangePasscodeNumberPadView(pin: $pin)
                    } else if currentStep == .createNew {
                        ChangePasscodeNumberPadView(pin: $newPin)
                    } else {
                        ChangePasscodeNumberPadView(pin: $newPinConfirmation)
                    }
                }
            }
            .navigationTitle(Text("settings_row_change_passcode"))
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: pinLength) { _ in
                if currentStep != .verifyOld {
                    resetNewPasscode()
                }
            }
            .onChange(of: pin) { newValue in
                if currentStep == .verifyOld && newValue.count == pinLength {
                    verifyOldPasscode()
                }
            }
            .onChange(of: newPin) { newValue in
                if currentStep == .createNew && newValue.count == pinLength {
                    currentStep = .confirmNew
                    newPinConfirmation = ""
                }
            }
            .onChange(of: newPinConfirmation) { newValue in
                if currentStep == .confirmNew && newValue.count == pinLength {
                    processNewPasscode()
                }
            }
        }
        
        private func verifyOldPasscode() {
            guard let savedPasscode = KeychainService.shared.getPasscode() else {
                errorMessage = "Không tìm thấy mã PIN. Vui lòng thử lại."
                resetAll()
                return
            }
            
            if pin == savedPasscode {
                // Mã PIN cũ đúng, chuyển sang bước tạo mới
                pin = ""
                currentStep = .createNew
                errorMessage = nil
            } else {
                // Mã PIN cũ sai
                errorMessage = "Mã PIN không đúng. Vui lòng thử lại."
                authManager.handleWrongPasscode()
                pin = ""
            }
        }
        
        private func processNewPasscode() {
            if newPin == newPinConfirmation {
                // KHỚP! -> Lưu mã PIN mới
                saveNewPasscode()
            } else {
                // KHÔNG KHỚP! -> Báo lỗi và làm lại
                errorMessage = "Mã PIN không khớp. Vui lòng thử lại."
                resetNewPasscode()
            }
        }
        
        private func resetNewPasscode() {
            newPin = ""
            newPinConfirmation = ""
            currentStep = .createNew
            errorMessage = nil
        }
        
        private func resetAll() {
            pin = ""
            newPin = ""
            newPinConfirmation = ""
            currentStep = .verifyOld
            errorMessage = nil
        }
        
        private func saveNewPasscode() {
            if KeychainService.shared.savePasscode(newPin) {
                print("Đã đổi mã PIN thành công.")
                errorMessage = nil
                dismiss()
            } else {
                errorMessage = "Không thể lưu mã PIN mới. Vui lòng thử lại."
                resetNewPasscode()
            }
        }
        
        // MARK: - Indicator View
        struct ChangePasscodeIndicator: View {
            @Binding var pin: String
            var pinLength: Int
            
            var body: some View {
                HStack(spacing: 20) {
                    ForEach(0..<pinLength, id: \.self) { index in
                        Circle()
                            .fill(index < pin.count ? Color.primary : Color.gray.opacity(0.3))
                            .frame(width: 15, height: 15)
                    }
                }
                .padding()
            }
        }
        
        // MARK: - Number Pad View
        struct ChangePasscodeNumberPadView: View {
            @Binding var pin: String
            private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 20), count: 3)
            private let buttons = [
                "1", "2", "3",
                "4", "5", "6",
                "7", "8", "9",
                "", "0", "delete.left"
            ]
            
            var body: some View {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(buttons, id: \.self) { button in
                        if button.isEmpty {
                            Rectangle().fill(Color.clear)
                        } else if button == "delete.left" {
                            Button(action: {
                                if !pin.isEmpty {
                                    pin.removeLast()
                                }
                            }) {
                                Image(systemName: "delete.left")
                                    .font(.title)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, minHeight: 60)
                            }
                        } else {
                            Button(action: {
                                if pin.count < 6 { // Giới hạn tối đa 6 số
                                    pin.append(button)
                                }
                            }) {
                                Text(button)
                                    .font(.title)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, minHeight: 60)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    // MARK: - Privacy Policy View
    struct PrivacyPolicyView: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("privacy_policy_title")
                            .font(.system(.title, design: .rounded).bold())
                            .foregroundColor(.primary)
                        
                        Text("privacy_policy_last_updated")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Section 1: Introduction
                    PrivacySectionView(
                        title: "privacy_policy_section_intro_title",
                        content: "privacy_policy_section_intro_content"
                    )
                    
                    // Section 2: Data Collection
                    PrivacySectionView(
                        title: "privacy_policy_section_data_collection_title",
                        content: "privacy_policy_section_data_collection_content"
                    )
                    
                    // Section 3: Data Usage
                    PrivacySectionView(
                        title: "privacy_policy_section_data_usage_title",
                        content: "privacy_policy_section_data_usage_content"
                    )
                    
                    // Section 4: Data Storage
                    PrivacySectionView(
                        title: "privacy_policy_section_data_storage_title",
                        content: "privacy_policy_section_data_storage_content"
                    )
                    
                    // Section 5: Data Security
                    PrivacySectionView(
                        title: "privacy_policy_section_data_security_title",
                        content: "privacy_policy_section_data_security_content"
                    )
                    
                    // Section 6: Your Rights
                    PrivacySectionView(
                        title: "privacy_policy_section_your_rights_title",
                        content: "privacy_policy_section_your_rights_content"
                    )
                    
                    // Section 7: Third-Party Services
                    PrivacySectionView(
                        title: "privacy_policy_section_third_party_title",
                        content: "privacy_policy_section_third_party_content"
                    )
                    
                    // Section 8: Changes to Policy
                    PrivacySectionView(
                        title: "privacy_policy_section_changes_title",
                        content: "privacy_policy_section_changes_content"
                    )
                    
                    // Section 9: Contact
                    PrivacySectionView(
                        title: "privacy_policy_section_contact_title",
                        content: "privacy_policy_section_contact_content"
                    )
                    
                    // Footer
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("privacy_policy_footer")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .background(AppColors.groupedBackground.ignoresSafeArea())
            .navigationTitle(Text("settings_row_privacy_policy"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Privacy Section View
    struct PrivacySectionView: View {
        let title: LocalizedStringKey
        let content: LocalizedStringKey
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(content)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)
        }
    }
}
