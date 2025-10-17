//
//  CategoryViewModel.swift
//  QuanLyChiTieu
//
//  Updated by Tạ Ngọc Tài on 25/8/25.
//

import Foundation
import CoreData
import Combine

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    private let context: NSManagedObjectContext
    
    // SỬA ĐỔI: Yêu cầu context phải được truyền vào khi khởi tạo.
    // Giờ đây nó sẽ dùng context mà TransactionAddScreen đang dùng.
    init(context: NSManagedObjectContext){
        self.context = context
        fecthAllCategories()
    }
    
    // Các hàm bên dưới không có gì thay đổi về logic
    func fecthAllCategories(){
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do{
            categories = try context.fetch(request)
        } catch{
            print("Lay du lieu Category loi: \(error)")
        }
    }
    
    func addCategory(name: String, type: String, iconName: String){
        let newCategory = Category(context: context)
        newCategory.id = UUID()
        newCategory.name = name
        newCategory.type = type
        newCategory.iconName = iconName
        newCategory.createAt = Date()
        newCategory.updateAt = Date()
        
        saveContext()
        fecthAllCategories()
    }
    
    func updateCategory(_ category: Category, name: String, type: String, iconName: String){
        category.name = name
        category.type = type
        category.iconName = iconName
        category.updateAt = Date()
                
        saveContext()
        fecthAllCategories()
    }
    
    func deleteCategory(_ category: Category){
        context.delete(category)
        saveContext()
        fecthAllCategories()
    }
    
    private func saveContext(){
        do{
            try context.save()
        } catch{
            print("Luu khong thanh cong, loi: \(error)")
        }
    }
}
