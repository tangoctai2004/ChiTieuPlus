import SwiftUI
import CoreData

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    
    @State private var tabSelection: Int = 1
    @Namespace private var animation
    
    @StateObject private var transactionFormViewModel = TransactionFormViewModel()
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    private let tabBarHeight: CGFloat = 80

    var body: some View {
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
            .background(Color(.systemGroupedBackground))
            .environmentObject(transactionFormViewModel)
            
            CustomTabBar(tabSelection: $tabSelection, animation: animation)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
