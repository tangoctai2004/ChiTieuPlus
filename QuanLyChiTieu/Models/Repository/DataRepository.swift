//
//  DataRepository.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 17/10/25.
//

import Foundation
import CoreData
import Combine

struct TransactionFormData {
    var transactionTitle: String
    var note: String
    var rawAmount: String
    var date: Date
    var type: String
    var selectedCategoryID: NSManagedObjectID?
}

class DataRepository {
    
    static let shared = DataRepository()
    // Giữ nguyên context là main context (viewContext)
    private let context: NSManagedObjectContext
    
    let categoriesPublisher = CurrentValueSubject<[Category], Never>([])
    let transactionsPublisher = CurrentValueSubject<[Transaction], Never>([])
    
    private init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }
    
    // MARK: - Category Functions (Giữ nguyên)
    
    func fetchCategories() {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            let categories = try context.fetch(request)
            categoriesPublisher.send(categories)
        } catch {
            print("❌ Lỗi khi fetch categories: \(error)")
            categoriesPublisher.send([])
        }
    }
    
    func addCategory(name: String, type: String, iconName: String) {
        let newCategory = Category(context: context)
        newCategory.id = UUID()
        newCategory.name = name
        newCategory.type = type
        newCategory.iconName = iconName
        newCategory.createAt = Date()
        newCategory.updateAt = Date()
        saveAndRefreshData()
    }
    
    func updateCategory(_ category: Category, name: String, type: String, iconName: String) {
        category.name = name
        category.type = type
        category.iconName = iconName
        category.updateAt = Date()
        saveAndRefreshData()
    }
    
    func deleteCategory(_ category: Category) {
        context.delete(category)
        saveAndRefreshData()
    }
    
    func fetchAllCategoriesSync() -> [Category] {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            // Dùng context của repository
            return try context.fetch(request)
        } catch {
            print("❌ Lỗi khi fetch categories sync: \(error)")
            return []
        }
    }
    
    // MARK: - Transaction Functions (ĐÃ TỐI ƯU)
    
    func fetchTransactions() {
        // --- SỬA ĐỔI ---
        // Sử dụng container để tạo background context và thực hiện fetch off-main-thread
        CoreDataStack.shared.container.performBackgroundTask { backgroundContext in
            
            let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
            
            do {
                // 1. Fetch trên luồng nền (background)
                let transactions = try backgroundContext.fetch(request)
                
                // 2. Lấy ObjectIDs để sử dụng an toàn trên Main Thread Context
                let transactionIDs = transactions.map { $0.objectID }
                
                // 3. Lấy lại các đối tượng trên Main Context (viewContext)
                let mainContext = self.context
                
                // Chuyển sang luồng Main Context để lấy object an toàn
                mainContext.perform {
                    let mainThreadTransactions = transactionIDs.compactMap {
                        // Lấy đối tượng từ ID trên main context
                        try? mainContext.existingObject(with: $0) as? Transaction
                    }
                    
                    // 4. Publish kết quả về Main Thread (Combine sẽ xử lý)
                    self.transactionsPublisher.send(mainThreadTransactions)
                }
                
            } catch {
                print("❌ Lỗi khi fetch transactions trên background: \(error)")
                self.transactionsPublisher.send([])
            }
        }
        // --- KẾT THÚC SỬA ĐỔI ---
    }

    func addTransaction(formData: TransactionFormData) {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        let title = formData.transactionTitle
        
        newTransaction.note = formData.note
        newTransaction.amount = AppUtils.currencyToDouble(formData.rawAmount)
        newTransaction.date = formData.date
        newTransaction.type = formData.type
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        if let categoryID = formData.selectedCategoryID,
           let categoryInContext = context.object(with: categoryID) as? Category {
            newTransaction.category = categoryInContext
            // Sửa logic title để dùng key
            newTransaction.title = title.isEmpty ? (categoryInContext.name ?? "common_category") : title
        } else {
            // Sửa logic title để dùng key
            newTransaction.title = title.isEmpty ? "common_category" : title
        }
        
        saveAndRefreshData()
    }
    
    func updateTransaction(
        _ transactionToEdit: Transaction,
        formData: TransactionFormData
    ) {
        let title = formData.transactionTitle
        transactionToEdit.note = formData.note
        transactionToEdit.amount = AppUtils.currencyToDouble(formData.rawAmount)
        transactionToEdit.date = formData.date
        transactionToEdit.type = formData.type
        transactionToEdit.updateAt = Date()

        if let categoryID = formData.selectedCategoryID,
           let categoryInContext = context.object(with: categoryID) as? Category {
            transactionToEdit.category = categoryInContext
            // Sửa logic title để dùng key
            transactionToEdit.title = title.isEmpty ? (categoryInContext.name ?? "common_category") : title
        } else {
            transactionToEdit.category = nil
            // Sửa logic title để dùng key
            transactionToEdit.title = title.isEmpty ? "common_category" : title
        }

        saveAndRefreshData()
    }

    func deleteTransaction(_ transaction: Transaction) {
        context.delete(transaction)
        saveAndRefreshData()
    }
    
    private func saveAndRefreshData() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            fetchCategories()
            fetchTransactions()
        } catch {
            print("❌ Lỗi khi lưu context: \(error)")
        }
    }
//    MARK: - RESET ALL DATA
    func resetAllData() {
        print("Bắt đầu quá trình reset (chỉ xoá Transactions)...")
        
        // 1. CHỈ tạo yêu cầu xóa cho Transaction
        let transactionDeleteRequest = NSBatchDeleteRequest(fetchRequest: Transaction.fetchRequest())
        transactionDeleteRequest.resultType = .resultTypeObjectIDs
        
        // (Chúng ta đã XÓA yêu cầu xóa Category)

        do {
            // 2. Thực thi yêu cầu xóa Transaction
            let transactionResult = try context.execute(transactionDeleteRequest) as? NSBatchDeleteResult

            // 3. Lấy ID của các đối tượng đã bị xóa
            let transactionObjectIDs = transactionResult?.result as? [NSManagedObjectID] ?? []
            
            // 4. Cập nhật context để xóa các đối tượng khỏi bộ nhớ
            if !transactionObjectIDs.isEmpty {
                let changes = [NSDeletedObjectsKey: transactionObjectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [context])
                print("✅ Đã xóa thành công \(transactionObjectIDs.count) transactions.")
            } else {
                print("Không tìm thấy transaction nào để xóa.")
            }
            
            // 5. Phát tín hiệu rỗng cho transactions,
            // KHÔNG làm gì categoriesPublisher
            transactionsPublisher.send([])
            
            // fetchCategories() // Có thể gọi fetch lại category nếu cần,
            // nhưng vì không thay đổi nên không bắt buộc.

        } catch {
            print("❌ Lỗi khi thực hiện reset transactions: \(error)")
        }
    }
}
