import SwiftUI

// Định nghĩa một View con để tạo kiểu dáng cho từng hàng (Row)
// Giúp code ở View chính sạch sẽ hơn và tái sử dụng
struct SettingsRowView: View {
    var iconName: String
    var title: String
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
                .foregroundColor(.primary) // Tự động đổi màu theo Light/Dark mode
            
            Spacer()
        }
        .padding(.vertical, 8) // Thêm một chút đệm cho hàng cao hơn
    }
}

struct SettingScreen: View {
    
    @State private var isAppLockEnabled: Bool = false
    @State private var isDailyReminderEnabled: Bool = true
    @State private var reminderTime: Date = Date()
    
    // Biến State để quản lý Picker giao diện
    @State private var appearance: AppearanceMode = .system
    
    enum AppearanceMode: String, CaseIterable, Identifiable {
        case light = "Sáng"
        case dark = "Tối"
        case system = "Hệ thống"
        var id: Self { self }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // --- SECTION 1: TÙY CHỈNH CHUNG ---
                Section(header: Text("Tùy Chỉnh Chung")) {
                    // NavigationLink dẫn đến một View khác
                    NavigationLink(destination: LanguageSelectionView()) {
                        SettingsRowView(iconName: "globe", title: "Ngôn ngữ", tintColor: .blue)
                    }
                    
                    // Sử dụng Picker bên trong List
                    Picker(selection: $appearance, label: SettingsRowView(iconName: "paintbrush", title: "Giao diện", tintColor: .purple)) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    
                    NavigationLink(destination: CurrencySelectionView()) {
                        SettingsRowView(iconName: "dollarsign.circle", title: "Tiền tệ chính", tintColor: .green)
                    }
                    
                    NavigationLink(destination: StartOfWeekView()) {
                        SettingsRowView(iconName: "calendar", title: "Ngày bắt đầu tuần", tintColor: .orange)
                    }
                }
                
                // --- SECTION 2: QUẢN LÝ DỮ LIỆU ---
                Section(header: Text("Quản lý Dữ liệu")) {
                    NavigationLink(destination: ManageCategoriesView()) {
                        SettingsRowView(iconName: "list.bullet.rectangle.portrait", title: "Quản lý Danh mục", tintColor: .cyan)
                    }
                    
                    // Button không phải là NavigationLink
                    Button(action: {
                        // Thêm hành động xuất dữ liệu tại đây
                        print("Export data tapped")
                    }) {
                        SettingsRowView(iconName: "arrow.up.doc", title: "Xuất Dữ liệu", tintColor: .gray)
                    }
                    // Cần set màu thủ công vì Button mặc định sẽ tô màu xanh
                    .foregroundColor(.primary)
                }
                
                // --- SECTION 3: BẢO MẬT ---
                Section(header: Text("Bảo mật")) {
                    // Toggle là một control đặc biệt trong List
                    Toggle(isOn: $isAppLockEnabled) {
                        SettingsRowView(iconName: "faceid", title: "Khóa ứng dụng (Face ID)", tintColor: .red)
                    }
                    
                    // Chỉ hiển thị hàng này nếu Khóa ứng dụng được bật
                    if isAppLockEnabled {
                        NavigationLink(destination: ChangePasscodeView()) {
                            SettingsRowView(iconName: "lock.shield", title: "Đổi mật khẩu", tintColor: .red)
                        }
                    }
                }
                
                // --- SECTION 4: THÔNG BÁO ---
                Section(header: Text("Thông báo")) {
                    Toggle(isOn: $isDailyReminderEnabled) {
                        SettingsRowView(iconName: "bell.badge", title: "Nhắc nhở hàng ngày", tintColor: .teal)
                    }
                    
                    if isDailyReminderEnabled {
                        // DatePicker cũng là một control đặc biệt
                        DatePicker(selection: $reminderTime, displayedComponents: .hourAndMinute) {
                            SettingsRowView(iconName: "clock", title: "Giờ nhắc nhở", tintColor: .teal)
                        }
                    }
                }
                
                // --- SECTION 5: VỀ ỨNG DỤNG ---
                Section(header: Text("Về ứng dụng")) {
                    // Link mở URL bên ngoài
                    Link(destination: URL(string: "https://www.apple.com/app-store/")!) {
                        SettingsRowView(iconName: "star", title: "Đánh giá ứng dụng", tintColor: .yellow)
                    }
                    .foregroundColor(.primary) // Cần set màu thủ công cho Link
                    
                    Link(destination: URL(string: "mailto:support@example.com")!) {
                        SettingsRowView(iconName: "bubble.left.and.bubble.right", title: "Góp ý & Hỗ trợ", tintColor: .mint)
                    }
                    .foregroundColor(.primary)
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRowView(iconName: "hand.raised", title: "Chính sách quyền riêng tư", tintColor: .gray)
                    }
                    
                    // Hàng chỉ hiển thị text, không tương tác
                    HStack {
                        SettingsRowView(iconName: "info.circle", title: "Phiên bản", tintColor: .gray)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
                
                // --- SECTION 6: VÙNG NGUY HIỂM ---
                Section(header: Text("Vùng Nguy hiểm")) {
                    Button(action: {
                        print("Reset data tapped")
                    }) {
                        SettingsRowView(iconName: "trash", title: "Đặt lại toàn bộ dữ liệu", tintColor: .red)
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(.insetGrouped) // Đây là style giống trong ảnh
            .navigationTitle("Cài Đặt") // Đặt tiêu đề cho trang
            .toolbar {
                // Thêm nút "Trợ giúp" giống như trong ảnh
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Trợ giúp") {
                        // Thêm hành động trợ giúp tại đây
                    }
                }
            }
        }
    }
}

// --- CÁC VIEW ĐÍCH (PLACEHOLDER) ---
// Đây là các View trống để các NavigationLink có thể hoạt động
// Bạn sẽ thay thế nội dung của chúng sau
struct LanguageSelectionView: View {
    var body: some View { Text("Chọn Ngôn ngữ").navigationTitle("Ngôn ngữ") }
}
struct CurrencySelectionView: View {
    var body: some View { Text("Chọn Tiền tệ").navigationTitle("Tiền tệ") }
}
struct StartOfWeekView: View {
    var body: some View { Text("Chọn Ngày bắt đầu tuần").navigationTitle("Ngày bắt đầu tuần") }
}
struct ManageCategoriesView: View {
    var body: some View { Text("Quản lý Danh mục").navigationTitle("Danh mục") }
}
struct ChangePasscodeView: View {
    var body: some View { Text("Thay đổi mật khẩu").navigationTitle("Đổi mật khẩu") }
}
struct PrivacyPolicyView: View {
    var body: some View { Text("Nội dung Chính sách Quyền riêng tư").navigationTitle("Chính sách Quyền riêng tư") }
}


// --- PREVIEW ---
// Dùng để xem trước giao diện trong Xcode
//#Preview {
//    SettingScreen()
//}
