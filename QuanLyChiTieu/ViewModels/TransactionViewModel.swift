//
//  TransactionViewModel.swift
//  QuanLyChiTieu
//
//  Updated by Tạ Ngọc Tài on 25/9/25.
//

import Foundation
import CoreData
import Combine

class TransactionViewModel: ObservableObject{
//    Hien thi danh sach giao dich
    @Published var transactions: [Transaction] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.context){
        self.context = context
        fetchAllTransactions()
    }
    
    func fetchAllTransactions(){
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        do{
            transactions = try context.fetch(request)
        }catch{
            print("Lay du lieu that bai, loi: \(error)")
        }
    }
    
    func addTransaction(title: String, amount: Double, type: String, date: Date, note: String?, category: Category){
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        newTransaction.title = title
        newTransaction.amount = amount
        newTransaction.type = (type == "income" || type == "expense") ? type : "expense"
        newTransaction.date = date
        newTransaction.note = note
        newTransaction.category = category
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        saveContext()
        fetchAllTransactions()
    }
    
    func deleteTransaction(_ transaction: Transaction){
        context.delete(transaction)
        
        saveContext()
        fetchAllTransactions()
    }
    
    func updateTransaction(_ transaction: Transaction, title: String, amount: Double, type: String, date: Date, note: String?, category: Category){
        transaction.title = title
        transaction.amount = amount
        transaction.type = (type == "income" || type == "expense") ? type : "expense"
        transaction.date = date
        transaction.note = note
        transaction.category = category
        transaction.updateAt = Date()
        
        saveContext()
        fetchAllTransactions()
    }
    
    // MARK: - Lấy tất cả giao dịch theo tháng và năm
    func fetchTransactions(forMonth month: Int, year: Int) -> [Transaction] {
        // Nếu month hoặc year không hợp lệ thì trả về []
        guard month > 0, month <= 12, year > 0 else { return [] }
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
        // Tạo ngày bắt đầu và kết thúc tháng
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        guard let startDate = calendar.date(from: components) else { return [] }
        
        var endComponents = DateComponents()
        endComponents.year = year
        endComponents.month = month + 1
        endComponents.day = 1
        guard let endDate = calendar.date(from: endComponents) else { return [] }
        
        // Lọc theo khoảng ngày
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Lỗi khi fetch Transaction theo tháng/năm: \(error)")
            return []
        }
    }
    
    // MARK: - Gom nhóm giao dịch theo ngày trong tháng/năm
    func fetchDailySummary(forMonth month: Int, year: Int) -> [(date: Date, income: Double, expense: Double)] {
        let transactions = fetchTransactions(forMonth: month, year: year)
        let grouped = Dictionary(grouping: transactions) { Calendar.current.startOfDay(for: $0.date ?? Date()) }
        
        return grouped.map { (date, items) in
            let income = items.filter { $0.type == "income" }.map(\.amount).reduce(0, +)
            let expense = items.filter { $0.type == "expense" }.map(\.amount).reduce(0, +)
            return (date: date, income: income, expense: expense)
        }
        .sorted { $0.date < $1.date }
    }
    
    private func saveContext(){
        if context.hashValue != 0{
            do{
                try context.save()
            }catch{
                print("Luu khong thanh cong, loi: \(error)")
            }
        }
    }
}

