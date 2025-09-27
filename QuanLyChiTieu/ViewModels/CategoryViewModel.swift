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
//    Hien thi danh sach category
    @Published var categories: [Category] = []
//    context de core data thao tac voi database
    private let context: NSManagedObjectContext
    
//    Truyen context tu CoreDataStack
    init(context: NSManagedObjectContext = CoreDataStack.shared.context){
        self.context = context
        fecthAllCategories()
    }
//    Fetch toan bo danh sach ban dau
    func fecthAllCategories(){
//        Du lieu duoc sap xep theo ten tang dan
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do{
            categories = try context.fetch(request)
        } catch{
            print("Lay du lieu Category loi: \(error)")
        }
    }
    
    func addCategory(name: String, type: String){
        let newCategory = Category(context: context)
        newCategory.id = UUID()
        newCategory.name = name
        newCategory.type = type
        newCategory.createAt = Date()
        newCategory.updateAt = Date()
        
        saveContext()
        fecthAllCategories()
    }
    
    func updateCategory(_ category: Category, name: String, type: String){
        category.name = name
        category.type = type
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

