import SwiftUI
import CoreData

struct ContentView: View {
    // Lấy context từ môi trường chung của ứng dụng
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTab: Tab = .home
    
    // SỬA ĐỔI: Sử dụng TransactionFormViewModel thay cho TransactionDraft
    // Điều này giúp giữ trạng thái form khi chuyển tab
    @StateObject private var transactionFormViewModel = TransactionFormViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeScreen()
                        .padding(.bottom, 80)
                case .category:
                    // SỬA ĐỔI: Không cần truyền context vào nữa
                    CategoryListScreen()
                        .padding(.bottom, 80)
                case .dashboard:
                    // SỬA ĐỔI: Trang này giờ sẽ nhận viewModel từ environment
                    TransactionAddScreen()
                        .padding(.bottom, 80)
                case .setting:
                    // DashboardScreen() là màn hình thống kê, bạn có thể thay thế sau
                    Text("Settings Screen")
                        .padding(.bottom, 80)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.white))
            // SỬA ĐỔI: Truyền TransactionFormViewModel vào môi trường
            .environmentObject(transactionFormViewModel)
            
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .zIndex(1)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// Toàn bộ phần enum Tab, CustomTabBar, và TabBarButton được giữ nguyên 100%
// theo code gốc của bạn để đảm bảo giao diện không đổi.

enum Tab {
    case home, category, dashboard, setting
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            TabBarButton(tab: .home,
                         title: "Trang Chủ",
                         systemImage: "house.fill",
                         selectedTab: $selectedTab)
            
            TabBarButton(tab: .category,
                         title: "Danh Mục",
                         systemImage: "tray.full",
                         selectedTab: $selectedTab)
            
            TabBarButton(tab: .dashboard,
                         title: "Thêm",
                         systemImage: "chart.bar.fill",
                         selectedTab: $selectedTab)
            
            TabBarButton(tab: .setting,
                         title: "Setting",
                         systemImage: "gearshape.fill",
                         selectedTab: $selectedTab)
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.clear)
        )
        .padding(.horizontal, 20)
        .zIndex(1)
    }
}

struct TabBarButton: View {
    let tab: Tab
    let title: String
    let systemImage: String
    @Binding var selectedTab: Tab
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.5)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(selectedTab == tab ? .orange : .gray)
                    .scaleEffect(selectedTab == tab ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(selectedTab == tab ? .orange : .gray)
                    .scaleEffect(selectedTab == tab ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selectedTab == tab ? Color.orange.opacity(0.15) : Color.clear)
                    .animation(.easeInOut(duration: 0.25), value: selectedTab)
            )
        }
    }
}
