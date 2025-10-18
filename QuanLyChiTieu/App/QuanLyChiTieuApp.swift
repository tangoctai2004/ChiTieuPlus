//
//  QuanLyChiTieuApp.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 27/8/25.
//

import SwiftUI
import CoreData

@main
struct QuanLyChiTieuApp: App {
    let persistenceController = PersistenceController.shared
    @State private var isShowingIntro = true

    // MARK: - Dữ liệu mẫu
    let defaultExpenses: [(name: String, iconName: String)] = [
        ("Ăn uống", "fork.knife"),
        ("Chi tiêu hàng ngày", "cart.fill"),
        ("Quần áo", "tshirt.fill"),
        ("Mỹ phẩm", "hand.raised.fingers.spread.fill"),
        ("Phí tiệc tùng", "party.popper.fill"),
        ("Y tế", "pills.fill"),
        ("Giáo dục", "graduationcap.fill"),
        ("Tiền điện", "bolt.fill"),
        ("Đi lại", "bus.fill"),
        ("Phí liên lạc", "phone.fill"),
        ("Tiền nhà", "house.fill")
    ]
    
    let defaultIncomes: [(name: String, iconName: String)] = [
        ("Tiền lương", "banknote.fill"),
        ("Tiền phụ cấp", "person.3.fill"),
        ("Tiền thưởng", "dollarsign.circle.fill"),
        ("Thu nhập phụ", "lightbulb.fill"),
        ("Đầu tư", "chart.line.uptrend.xyaxis"),
        ("Thu nhập tạm thời", "briefcase.fill")
    ]

    // MARK: - Hàm khởi tạo App
    init() {
        seedDefaultCategoriesIfNeeded(
            context: persistenceController.container.viewContext
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack{
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .opacity(isShowingIntro ? 0 : 1)
                
                if isShowingIntro {
                    IntroView(isShowingIntro: $isShowingIntro)
                        .zIndex(1)
                }
            }
            .animation(.easeIn(duration: 0.5), value: isShowingIntro)
        }
    }
    
    // MARK: - Hàm Seed Dữ liệu
    func seedDefaultCategoriesIfNeeded(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Category> = Category.fetchRequest()
        
        do {
            let existingCount = try context.count(for: fetchRequest)
            guard existingCount == 0 else {
                print("✅ Dữ liệu Category đã tồn tại, không cần seed.")
                return
            }
        } catch {
            print("❌ Lỗi khi kiểm tra Category: \(error)")
            return
        }

        for categoryInfo in defaultExpenses {
            let cat = Category(context: context)
            cat.id = UUID()
            cat.name = categoryInfo.name
            cat.type = "expense"
            cat.iconName = categoryInfo.iconName
            cat.createAt = Date()
            cat.updateAt = Date()
        }

        for categoryInfo in defaultIncomes {
            let cat = Category(context: context)
            cat.id = UUID()
            cat.name = categoryInfo.name
            cat.type = "income"
            cat.iconName = categoryInfo.iconName
            cat.createAt = Date()
            cat.updateAt = Date()
        }

        do {
            try context.save()
            print("✅ Đã seed thành công các category mặc định.")
        } catch {
            print("❌ Lỗi khi lưu các category mặc định: \(error)")
        }
    }
}
