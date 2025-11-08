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
    
    @StateObject private var languageSettings = LanguageSettings()

    // --- SỬA ĐỔI ---
    // Đổi tên tuple từ 'name' thành 'nameKey'
    let defaultExpenses: [(nameKey: String, iconName: String)] = [
        ("default_category_food", "fork.knife"),
        ("default_category_daily_spending", "cart.fill"),
        ("default_category_clothing", "tshirt.fill"),
        ("default_category_cosmetics", "hand.raised.fingers.spread.fill"),
        ("default_category_party", "party.popper.fill"),
        ("default_category_medical", "pills.fill"),
        ("default_category_education", "graduationcap.fill"),
        ("default_category_electricity", "bolt.fill"),
        ("default_category_transport", "bus.fill"),
        ("default_category_communication", "phone.fill"),
        ("default_category_housing", "house.fill")
    ]
    
    let defaultIncomes: [(nameKey: String, iconName: String)] = [
        ("default_category_salary", "banknote.fill"),
        ("default_category_allowance", "person.3.fill"),
        ("default_category_bonus", "dollarsign.circle.fill"),
        ("default_category_side_income", "lightbulb.fill"),
        ("default_category_investment", "chart.line.uptrend.xyaxis"),
        ("default_category_temporary_income", "briefcase.fill")
    ]
    // --- KẾT THÚC SỬA ĐỔI ---

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
            
            .environmentObject(languageSettings)
            .environment(\.locale, .init(identifier: languageSettings.selectedLanguage))
            .onOpenURL { url in
                print("Đã nhận được URL: \(url.path)")
                if url.pathExtension == "csv" {
                    // Gọi service để xử lý
                    CSVService.shared.parseAndImport(url: url)
                }
            }
        }
    }
    
    // --- SỬA ĐỔI QUAN TRỌNG ---
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

        // Sửa ở đây: Lưu 'nameKey' (khóa) trực tiếp vào database
        for categoryInfo in defaultExpenses {
            let cat = Category(context: context)
            cat.id = UUID()
            cat.name = categoryInfo.nameKey // <-- LƯU KEY
            cat.type = "expense"
            cat.iconName = categoryInfo.iconName
            cat.createAt = Date()
            cat.updateAt = Date()
        }

        // Sửa ở đây: Lưu 'nameKey' (khóa) trực tiếp vào database
        for categoryInfo in defaultIncomes {
            let cat = Category(context: context)
            cat.id = UUID()
            cat.name = categoryInfo.nameKey // <-- LƯU KEY
            cat.type = "income"
            cat.iconName = categoryInfo.iconName
            cat.createAt = Date()
            cat.updateAt = Date()
        }
        // --- KẾT THÚC SỬA ĐỔI ---

        do {
            try context.save()
            print("✅ Đã seed thành công các category mặc định (đã lưu key).")
        } catch {
            print("❌ Lỗi khi lưu các category mặc định: \(error)")
        }
    }
}
