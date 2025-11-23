import SwiftUI
import CoreData

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    
    // 1. Tạo nguồn quản lý Auth duy nhất
    @StateObject private var authManager = LocalAuthManager()
    
    @State private var tabSelection: Int = 1
    @Namespace private var animation
    
    @StateObject private var transactionFormViewModel = TransactionFormViewModel()
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    private let tabBarHeight: CGFloat = 80

    var body: some View {
        ZStack {
            
            // --- 1. GIAO DIỆN APP CHÍNH (TABVIEW) ---
            ZStack(alignment: .bottom) {
                Group {
                    switch tabSelection {
                    case 1:
                        HomeScreen()
                            .padding(.bottom, tabBarHeight)
                    case 2:
                        CategoryListScreen()
                            .padding(.bottom, tabBarHeight)
                    case 3:
                        TransactionAddScreen()
                            .padding(.bottom, tabBarHeight)
                    case 4:
                        DashboardScreen()
                            .padding(.bottom, tabBarHeight)
                    case 5:
                        SettingScreen()
                            .padding(.bottom, tabBarHeight)
                    default:
                        HomeScreen()
                            .padding(.bottom, tabBarHeight)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppColors.groupedBackground)
                .environmentObject(transactionFormViewModel)
                .environmentObject(authManager) // <-- Chia sẻ AuthManager
                
                CustomTabBar(tabSelection: $tabSelection, animation: animation)
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onReceive(NotificationCenter.default.publisher(for: .didTapDailyReminder)) { _ in
                transactionFormViewModel.reset()
                self.tabSelection = 3
            }
            // --- SỬA LỖI Ở ĐÂY ---
            // Ẩn nội dung app nếu chưa mở khóa
            .blur(radius: authManager.isUnlocked ? 0 : 20) // <-- Thêm "radius:"
            // --- KẾT THÚC SỬA LỖI ---

            
            // --- 2. MÀN HÌNH KHÓA (NẰM TRÊN CÙNG) ---
            if !authManager.isUnlocked {
                // Nếu cần nhập mã PIN (do Face ID fail hoặc không bật)
                if authManager.needsPasscodeEntry {
                    EnterPasscodeView(authManager: authManager)
                        .zIndex(2) // Nằm trên
                        .transition(.opacity)
                } else {
                    // Nếu ưu tiên Face ID
                    // Lớp phủ mờ
                    Rectangle()
                        .fill(.thinMaterial)
                        .ignoresSafeArea()
                        .zIndex(1)
                    
                    // Nút Face ID
                    VStack(spacing: 20) {
                        Image(systemName: "faceid")
                            .font(.system(size: 60))
                            .foregroundColor(.primary)
                        
                        Text("Nhấn để mở khóa")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        authManager.authenticate() // Gọi hàm xác thực
                    }
                    .zIndex(2) // Nằm trên cùng
                }
            }
            
        } // Kết thúc ZStack chính
        .onAppear {
            // Khi app vừa mở, yêu cầu xác thực ngay
            if !authManager.isUnlocked {
                authManager.authenticate()
            }
            // Xử lý recurring transactions khi app khởi động
            DataRepository.shared.processDueRecurringTransactions()
        }
        .onChange(of: authManager.isUnlocked) { _ in
            // Không cần làm gì khi unlock
        }
        .onChange(of: scenePhase) { newPhase in
            // Nếu app bị đưa ra ngoài (vd: nhấn Home)
            if newPhase == .background || newPhase == .inactive {
                authManager.lockApp() // Khóa app
            }
            // Nếu app được mở lại
            if newPhase == .active {
                if !authManager.isUnlocked {
                    authManager.authenticate() // Yêu cầu xác thực
                }
                // Xử lý recurring transactions khi app trở lại active
                DataRepository.shared.processDueRecurringTransactions()
            }
        }
    }
}
