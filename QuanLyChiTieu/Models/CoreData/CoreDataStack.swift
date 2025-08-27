//
//  CoreDataStack.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 27/8/25.
//

import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    private init() {
        container = NSPersistentContainer(name: "QuanLyChiTieu")
//        Load database
        container.loadPersistentStores { description, error in
            if let error = error{
                fatalError("Ket noi khong thanh cong Core Data Stack: \(error)")
            }
        }
//        Tự động gộp thay đổi từ background vào main context
        container.viewContext.automaticallyMergesChangesFromParent = true
        
    }
    
//    Thao tac du lieu UI Thread
    var context: NSManagedObjectContext{
        container.viewContext
    }
    
//    func luu thay doi ve lai database
    func saveContext(){
        let context = container.viewContext
        if context.hasChanges{
            do{
                try context.save()
            } catch{
                print("Luu khong thanh cong, bi loi: \(error.localizedDescription)")
            }
        }
        
    }
}
