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
    // SỬA LỖI Ở ĐÂY: Phải là NSManagedObjectID?
    var selectedCategoryID: NSManagedObjectID?
}

class DataRepository {
    
    static let shared = DataRepository()
    private let context: NSManagedObjectContext
    
    let categoriesPublisher = CurrentValueSubject<[Category], Never>([])
    let transactionsPublisher = CurrentValueSubject<[Transaction], Never>([])
    
    private init(context: NSManagedObjectContext = CoreDataStack.shared.context) {
        self.context = context
    }
    
    // MARK: - Category Functions
    
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
    
    // MARK: - Transaction Functions
    
    func fetchTransactions() {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        do {
            let transactions = try context.fetch(request)
            transactionsPublisher.send(transactions)
        } catch {
            print("❌ Lỗi khi fetch transactions: \(error)")
            transactionsPublisher.send([])
        }
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
        
        // Bây giờ 'categoryID' đã đúng kiểu NSManagedObjectID?
        if let categoryID = formData.selectedCategoryID,
           let categoryInContext = context.object(with: categoryID) as? Category {
            newTransaction.category = categoryInContext
            newTransaction.title = title.isEmpty ? (categoryInContext.name ?? "Giao dịch") : title
        } else {
            newTransaction.title = title.isEmpty ? "Giao dịch" : title
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

        // Bây giờ 'categoryID' đã đúng kiểu NSManagedObjectID?
        if let categoryID = formData.selectedCategoryID,
           let categoryInContext = context.object(with: categoryID) as? Category {
            transactionToEdit.category = categoryInContext
            transactionToEdit.title = title.isEmpty ? (categoryInContext.name ?? "Giao dịch") : title
        } else {
            transactionToEdit.category = nil
            transactionToEdit.title = title.isEmpty ? "Giao dịch" : title
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
}
