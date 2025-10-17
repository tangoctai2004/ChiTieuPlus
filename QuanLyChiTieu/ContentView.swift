import SwiftUI

struct ContentView: View {
    // Lấy context từ môi trường chung của ứng dụng
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeScreen()
                        .padding(.bottom, 80)
                case .add:
                    // SỬA ĐỔI QUAN TRỌNG:
                    // Truyền context vào CategoryListScreen.
                    // Đây là bước kết nối để mọi thứ hoạt động đồng bộ.
                    CategoryListScreen(context: context)
                        .padding(.bottom, 80)
                case .dashboard:
                    TransactionAddScreen() // <- Trang này không cần thay đổi gì cả
                        .padding(.bottom, 80)
                case .setting:
                    DashboardScreen()
                        .padding(.bottom, 80)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.white))
            
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 20)
                .zIndex(1)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

enum Tab {
    case home, add, dashboard, setting
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack {
            TabBarButton(tab: .home,
                         title: "Home",
                         systemImage: "house.fill",
                         selectedTab: $selectedTab)
            
            TabBarButton(tab: .add,
                         title: "Add",
                         systemImage: "tray.full",
                         selectedTab: $selectedTab)
            
            TabBarButton(tab: .dashboard,
                         title: "Dashboard",
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
