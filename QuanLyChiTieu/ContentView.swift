import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var context
    
    var body: some View {
        TabView{  //Tab bar
            HomeScreen()
                .tabItem {
                    Label("Thu / Chi", systemImage: "list.bullet")
                }
            CategoryManageScreen()
                .tabItem {
                    Label("Danh Mục", systemImage: "folder")
                }
            TransactionAddScreen()
                .tabItem {
                    Label("Thêm giao dịch", systemImage: "plus.circle")
                }
            DashboardScreen()
                .tabItem {
                    Label("Thống kê", systemImage: "chart.pie")
                }
        }
    }
}

//Hien thi canvas
//#Preview {
//    ContentView()
//        .environment(\.managedObjectContext, CoreDataStack.shared.context) //Truyền context mẫu
//}


