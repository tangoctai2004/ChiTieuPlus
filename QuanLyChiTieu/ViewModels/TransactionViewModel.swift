import Foundation
import CoreData
import Combine

class TransactionViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    
    private let context: NSManagedObjectContext
    
    // Yêu cầu context được truyền vào để nhất quán
    init(context: NSManagedObjectContext) {
        self.context = context
        fetchAllTransactions()
    }
    
    // Giữ lại hàm fetch toàn bộ danh sách
    func fetchAllTransactions() {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        do {
            transactions = try context.fetch(request)
        } catch {
            print("Lay du lieu that bai, loi: \(error)")
        }
    }
    
    // Giữ lại các hàm fetch và xử lý dữ liệu cho báo cáo, thống kê
    // MARK: - Lấy tất cả giao dịch theo tháng và năm
    func fetchTransactions(forMonth month: Int, year: Int) -> [Transaction] {
        guard month > 0, month <= 12, year > 0 else { return [] }
        
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        
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
    
    // Hàm saveContext không còn cần thiết ở đây vì ViewModel này chỉ đọc dữ liệu
}
