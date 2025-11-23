# Chi Tiêu+ (Expense+)

Ứng dụng quản lý chi tiêu cá nhân đầy đủ tính năng, được xây dựng bằng SwiftUI cho iOS.

## 📱 Giới thiệu

Chi Tiêu+ là ứng dụng quản lý tài chính cá nhân giúp bạn theo dõi thu nhập, chi tiêu, lập ngân sách và đạt mục tiêu tiết kiệm một cách dễ dàng và trực quan.

## ✨ Tính năng chính

### 💰 Quản lý giao dịch
- Thêm, sửa, xóa giao dịch thu nhập và chi tiêu
- Tìm kiếm giao dịch theo tiêu đề, ghi chú, danh mục
- Lọc giao dịch theo loại (Thu nhập/Chi tiêu/Tất cả)
- Nhập liệu bằng giọng nói (Speech Recognition)
- Hỗ trợ nhiều loại tiền tệ (VND, USD)

### 📊 Dashboard & Thống kê
- Biểu đồ tròn (Pie Chart) phân tích chi tiêu theo danh mục
- Xem thống kê theo tháng hoặc năm
- Tổng hợp thu nhập, chi tiêu và số dư
- Chi tiết từng danh mục với biểu đồ cột

### 📁 Quản lý danh mục
- Tạo, sửa, xóa danh mục tùy chỉnh
- Danh mục mặc định cho thu nhập và chi tiêu
- Icon và màu sắc đa dạng

### 💵 Ngân sách (Budget)
- Tạo ngân sách theo danh mục hoặc tổng thể
- Theo dõi chi tiêu so với ngân sách
- Cảnh báo khi gần vượt hoặc vượt ngân sách
- Hỗ trợ ngân sách theo tuần/tháng/năm

### 🎯 Mục tiêu tiết kiệm
- Đặt mục tiêu tiết kiệm với thời hạn
- Theo dõi tiến độ tiết kiệm
- Gia hạn mục tiêu khi cần

### 🔄 Giao dịch định kỳ
- Tạo giao dịch tự động lặp lại (hàng ngày/tuần/tháng/năm)
- Tự động tạo giao dịch khi đến hạn
- Quản lý các giao dịch định kỳ

### 🔒 Bảo mật
- Mã PIN 6 số
- Xác thực sinh trắc học (Face ID/Touch ID)
- Tự động khóa khi app vào background
- Lưu trữ mật khẩu an toàn bằng Keychain

### 🌍 Đa ngôn ngữ
- Tiếng Việt
- Tiếng Anh
- Tự động chuyển đổi theo cài đặt hệ thống

### 🎨 Giao diện
- Dark Mode / Light Mode
- Custom Tab Bar với animation mượt mà
- UI hiện đại, dễ sử dụng
- Responsive design

### 📤 Xuất/Nhập dữ liệu
- Xuất dữ liệu ra file CSV
- Nhập dữ liệu từ file CSV
- Backup và khôi phục dữ liệu

### 🔔 Thông báo
- Nhắc nhở nhập giao dịch hàng ngày
- Cảnh báo ngân sách
- Thông báo giao dịch định kỳ

### ⚙️ Cài đặt khác
- Chọn ngày bắt đầu tuần (Chủ nhật → Thứ Bảy)
- Chính sách bảo mật và quyền riêng tư
- Đổi mật khẩu

## 🛠 Công nghệ

- **Framework**: SwiftUI
- **Language**: Swift 5.9+
- **Database**: Core Data
- **Architecture**: MVVM (Model-View-ViewModel)
- **Dependencies**: 
  - Swift Charts (biểu đồ)
  - Combine (reactive programming)
  - Local Authentication (Face ID/Touch ID)
  - Speech Recognition

## 📋 Yêu cầu hệ thống

- iOS 16.0 trở lên
- Xcode 15.0 trở lên (để build)
- Swift 5.9+

## 🚀 Cài đặt

1. Clone repository:
```bash
git clone <repository-url>
cd ChiTieuPlus
```

2. Mở project trong Xcode:
```bash
open QuanLyChiTieu.xcodeproj
```

3. Build và chạy trên Simulator hoặc thiết bị thật

## 📁 Cấu trúc project

```
QuanLyChiTieu/
├── App/                    # App entry point
│   ├── QuanLyChiTieuApp.swift
│   └── Persistence.swift
├── Views/                  # SwiftUI Views
│   ├── HomeScreen.swift
│   ├── Dashboard/
│   ├── Category/
│   ├── Transaction/
│   ├── Settings/
│   └── Tabbar/
├── ViewModels/             # ViewModels (MVVM)
│   ├── Dashboard/
│   ├── Transaction/
│   ├── Budget/
│   └── ...
├── Models/                 # Data Models
│   ├── CoreData/           # Core Data entities
│   └── Repository/         # DataRepository
├── Helpers/                # Utilities & Services
│   ├── AppUtils.swift
│   ├── CurrencySettings.swift
│   ├── LocalAuthManager.swift
│   └── ...
└── Resources/
    ├── Localizable.strings  # Localization
    └── Assets.xcassets      # Images & Colors
```

## 💾 Cơ sở dữ liệu

App sử dụng Core Data với các Entity chính:

- **Transaction**: Giao dịch (thu nhập/chi tiêu)
- **Category**: Danh mục
- **Budget**: Ngân sách
- **SavingsGoal**: Mục tiêu tiết kiệm
- **RecurringTransaction**: Giao dịch định kỳ

## 🎯 Hướng dẫn sử dụng

### Thêm giao dịch mới
1. Chọn tab "Thêm" (dấu +)
2. Chọn loại (Thu nhập/Chi tiêu)
3. Nhập số tiền, chọn danh mục, ngày
4. Nhấn "Lưu"

### Xem thống kê
1. Chọn tab "Dashboard"
2. Chọn "Hàng Tháng" hoặc "Hàng Năm"
3. Xem biểu đồ và danh sách chi tiết

### Tạo ngân sách
1. Vào "Cài đặt" → "Ngân sách"
2. Nhấn "Thêm ngân sách"
3. Chọn danh mục, số tiền, chu kỳ
4. Lưu

### Đặt mục tiêu tiết kiệm
1. Vào "Cài đặt" → "Mục tiêu tiết kiệm"
2. Nhấn "Thêm mục tiêu"
3. Nhập số tiền và thời hạn
4. Lưu

## 🔐 Quyền truy cập

App yêu cầu các quyền sau:
- **Face ID/Touch ID**: Để mở khóa app
- **Microphone**: Để nhập liệu bằng giọng nói
- **Speech Recognition**: Để nhận diện giọng nói

## 📝 License

[Thêm thông tin license nếu có]

## 👨‍💻 Tác giả

[Thêm thông tin tác giả]

## 🙏 Cảm ơn

Cảm ơn bạn đã sử dụng Chi Tiêu+!

---

**Lưu ý**: Đây là project cá nhân, dữ liệu được lưu trữ cục bộ trên thiết bị của bạn.

