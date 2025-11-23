import Foundation
import Combine
import CoreData
import SwiftUI

struct GroupedTransactions: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    var items: [Transaction]
}

class MonthlyCategoryStatisticViewModel: ObservableObject {
    
    // ... (Các thuộc tính @Published giữ nguyên) ...
    @Published var monthlyChartData: [ChartDataPoint] = []
    @Published var selectedChartMonth: Int?
    @Published var displayedTransactions: [Transaction] = []
    @Published var groupedDisplayedTransactions: [GroupedTransactions] = []

    // ... (Các thuộc tính Read-only giữ nguyên) ...
    let categoryName: String // Chứa KEY của Category
    let categoryColor: Color
    let initialMonthLabel: String
    
    var localizedCategoryName: LocalizedStringKey {
        return LocalizedStringKey(categoryName)
    }
    
    var selectedPeriodString: String {
        let month = selectedChartMonth ?? initialSelectedMonth
        let year = selectedYear
        
        // Lấy Locale từ LanguageSettings
        let selectedLocaleID = (try? LanguageSettings().selectedLanguage) ?? Locale.current.identifier

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: selectedLocaleID)
        formatter.dateFormat = "M/yyyy"
        
        var components = DateComponents()
        components.year = year
        components.month = month
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(month)/\(year)"
    }

    // ... (Các thuộc tính Private giữ nguyên) ...
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    private var allTransactionsForYear: [Transaction] = []
    private let selectedYear: Int
    private let initialSelectedMonth: Int
    private let categoryToFilter: String
    
    // MARK: - Init
    
    init(
        categorySummary: CategorySummary,
        selectedMonth: Int,
        selectedYear: Int,
        repository: DataRepository = .shared
    ) {
        self.categoryName = categorySummary.name
        self.categoryColor = categorySummary.color
        self.categoryToFilter = categorySummary.name
        
        self.selectedYear = selectedYear
        self.initialSelectedMonth = selectedMonth
        
        self.repository = repository
        
        // --- (BẮT ĐẦU SỬA ĐỔI) ---
        
        // 1. Lấy ngôn ngữ app đã lưu
        let selectedLocaleID = (try? LanguageSettings().selectedLanguage) ?? Locale.current.identifier

        // 2. Khởi tạo formatter (chỉ dùng cho trường hợp không phải tiếng Việt)
        let monthFormatter: DateFormatter = {
            let f = DateFormatter()
            f.locale = Locale(identifier: selectedLocaleID)
            f.dateFormat = "MMM"
            return f
        }()
        
        // 3. Tạo ChartDataPoint với logic kiểm tra ngôn ngữ
        let initialChartData = (1...12).map { month -> ChartDataPoint in
            
            let monthName: String // Khai báo biến
            
            if selectedLocaleID == "vi" {
                // Yêu cầu của bạn: "T1", "T2", ...
                monthName = "T\(month)"
            } else {
                // Giữ logic cũ cho các ngôn ngữ khác (vd: "Jan", "Feb" cho tiếng Anh)
                var components = DateComponents()
                components.year = selectedYear
                components.month = month
                let date = Calendar.current.date(from: components)!
                monthName = monthFormatter.string(from: date)
            }
            
            return ChartDataPoint(month: month, monthLabel: monthName, totalAmount: 0)
        }
        
        // 4. Gán giá trị cho các thuộc tính đã Published
        self.monthlyChartData = initialChartData
        
        // 5. Sử dụng biến cục bộ để gán initialMonthLabel một cách an toàn
        self.initialMonthLabel = initialChartData[initialSelectedMonth - 1].monthLabel
        
        // --- (KẾT THÚC SỬA ĐỔI) ---
        
        self.selectedChartMonth = initialSelectedMonth
        
        subscribeToRepository()
        repository.fetchTransactions()
    }
    
    // ... (Phần còn lại của file giữ nguyên) ...
    
    private func subscribeToRepository() {
        repository.transactionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] allTransactions in
                self?.processTransactions(allTransactions: allTransactions)
            }
            .store(in: &cancellables)
    }

    // MARK: - Core Logic
    
    private func processTransactions(allTransactions: [Transaction]) {
        
        var components = DateComponents()
        components.year = self.selectedYear
        guard let startOfYear = Calendar.current.date(from: components),
              let endOfYear = Calendar.current.date(byAdding: .year, value: 1, to: startOfYear) else { return }

        self.allTransactionsForYear = allTransactions.filter {
            guard let date = $0.date else { return false }
            let txCategoryName = $0.category?.name ?? "Khác"
            return date >= startOfYear && date < endOfYear && txCategoryName == self.categoryToFilter
        }
        
        var newChartData = self.monthlyChartData
        
        newChartData = newChartData.map { ChartDataPoint(month: $0.month, monthLabel: $0.monthLabel, totalAmount: 0) }
        
        for transaction in self.allTransactionsForYear {
            guard let date = transaction.date else { continue }
            let month = Calendar.current.component(.month, from: date)
            // Validate amount trước khi cộng
            let amount = transaction.amount
            let safeAmount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
            // Validate totalAmount hiện tại trước khi cộng
            let currentTotal = newChartData[month - 1].totalAmount
            let safeCurrentTotal = currentTotal.isFinite && !currentTotal.isNaN ? currentTotal : 0
            newChartData[month - 1].totalAmount = safeCurrentTotal + safeAmount
        }
        
        self.monthlyChartData = newChartData
        
        updateDisplayedTransactions(for: self.selectedChartMonth ?? self.initialSelectedMonth)
    }
    
    func updateDisplayedTransactions(for month: Int) {
        self.selectedChartMonth = month
        
        self.displayedTransactions = self.allTransactionsForYear.filter {
            guard let date = $0.date else { return false }
            let monthComponent = Calendar.current.component(.month, from: date)
            return monthComponent == month
        }
        .sorted(by: { $0.date! > $1.date! })
        
        let grouped = Dictionary(grouping: self.displayedTransactions) {
            Calendar.current.startOfDay(for: $0.date!)
        }
        
        self.groupedDisplayedTransactions = grouped.map { (date, transactions) in
            GroupedTransactions(date: date, items: transactions)
        }.sorted(by: { $0.date > $1.date })
    }
    
    var displayedTransactionsTotal: Double {
        displayedTransactions.reduce(0) { sum, transaction in
            let amount = transaction.amount
            let safeAmount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
            return sum + safeAmount
        }
    }

    // MARK: - View Helpers
    
    func formattedSectionHeaderDate(_ date: Date) -> String {
        let selectedLocaleID = (try? LanguageSettings().selectedLanguage) ?? Locale.current.identifier
        
        let headerFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: selectedLocaleID)
            formatter.dateFormat = "dd/MM/yyyy"
            return formatter
        }()
        
        // Giả định bạn đã thêm key cho "Hôm nay" và "Hôm qua" vào Localizable.strings
        if Calendar.current.isDateInToday(date) {
            return NSLocalizedString("Hôm nay", comment: "Today")
        }
        if Calendar.current.isDateInYesterday(date) {
            return NSLocalizedString("Hôm qua", comment: "Yesterday")
        }
        return headerFormatter.string(from: date)
    }
}
