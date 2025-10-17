import SwiftUI
import CoreData

class TransactionEditViewModel: ObservableObject {
    private let transactionToEdit: Transaction
    private let context: NSManagedObjectContext
    
    @Published var transactionTitle: String
    @Published var note: String
    @Published var rawAmount: String
    @Published var formattedAmount: String
    @Published var date: Date
    @Published var type: String {
        didSet {
            if oldValue != type {
                selectedCategory = nil
            }
        }
    }
    @Published var selectedCategory: Category?
    
    init(transaction: Transaction, context: NSManagedObjectContext) {
        self.transactionToEdit = transaction
        self.context = context
        
        _transactionTitle = Published(initialValue: transaction.title ?? "")
        _note = Published(initialValue: transaction.note ?? "")
        _date = Published(initialValue: transaction.date ?? Date())
        _type = Published(initialValue: transaction.type ?? "expense")
        _selectedCategory = Published(initialValue: transaction.category)
        
        // SỬA ĐỔI QUAN TRỌNG:
        // Chuyển Double thành Int trước để loại bỏ phần thập phân ".0"
        let initialRawAmount = String(Int(transaction.amount))
        
        // Dùng chuỗi đã được xử lý đúng để khởi tạo cho cả hai biến
        _rawAmount = Published(initialValue: initialRawAmount)
        _formattedAmount = Published(initialValue: AppUtils.formatCurrencyInput(initialRawAmount))
    }
    
    var canSave: Bool {
        AppUtils.currencyToDouble(rawAmount) > 0 && selectedCategory != nil
    }
    
    func saveChanges() {
        transactionToEdit.title = transactionTitle
        transactionToEdit.note = note
        transactionToEdit.amount = AppUtils.currencyToDouble(rawAmount)
        transactionToEdit.date = date
        transactionToEdit.type = type
        transactionToEdit.category = selectedCategory
        transactionToEdit.updateAt = Date()
        
        do {
            try context.save()
        } catch {
            print("❌ Lỗi khi cập nhật Transaction: \(error)")
        }
    }
    
    func deleteTransaction() {
        context.delete(transactionToEdit)
        do {
            try context.save()
        } catch {
            print("❌ Lỗi khi xoá Transaction: \(error)")
        }
    }
}
