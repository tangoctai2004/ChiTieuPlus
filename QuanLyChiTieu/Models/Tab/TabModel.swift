import Foundation
import SwiftUI

enum TabModel: String, CaseIterable {
    case home = "tabbar_home"
    case category = "tabbar_category"
    case transaction = "tabbar_add"
    case statistics = "tabbar_statistic"
    case setting = "tabbar_setting"
    
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
    
    var localizedName: LocalizedStringKey {
        return LocalizedStringKey(self.rawValue)
    }
}
