import Foundation

enum TabModel: String, CaseIterable {
    case home = "Trang Chủ"
    case category = "Danh Mục"
    case transaction = "Thêm"
    case statistics = "Thống kê"
    case setting = "Cài đặt"
    
    // Cung cấp icon cho mỗi tab
    var systemImage: String {
        switch self {
        case .home:
            return "house.fill"
        case .category:
            return "tray.full"
        case .transaction:
            return "plus" 
        case .statistics:
            return "chart.bar.fill"
        case .setting:
            return "gearshape.fill"
        }
    }
}
