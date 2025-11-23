import Foundation
import Combine
import CoreData
import SwiftUI

class DashboardViewModel: ObservableObject {
    
    // MARK: - State
    @Published var periodSelection: Int = 0
    @Published var chartTabSelection: Int = 0
    @Published var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @Published var selectedYear: Int = Calendar.current.component(.year, from: Date())

    // MARK: - Published Data
    
    @Published var monthlyTransactions: [Transaction] = []
    @Published var yearlyTransactions: [Transaction] = []
    
    @Published var totalMonthlyIncome: Double = 0
    @Published var totalMonthlyExpense: Double = 0
    @Published var netMonthlyBalance: Double = 0
    
    @Published var totalYearlyIncome: Double = 0
    @Published var totalYearlyExpense: Double = 0
    @Published var netYearlyBalance: Double = 0
    
    @Published var monthlyExpensePieData: [CategorySummary] = []
    @Published var monthlyIncomePieData: [CategorySummary] = []
    @Published var yearlyExpensePieData: [CategorySummary] = []
    @Published var yearlyIncomePieData: [CategorySummary] = []

    // MARK: - Private Properties
    private var allTransactions: [Transaction] = []
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Display Properties (ĐÃ SỬA: Áp dụng Localization)
    
    var currentMonthDisplay: String {
        let selectedLocaleID = (try? LanguageSettings().selectedLanguage) ?? Locale.current.identifier
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: selectedLocaleID)
        formatter.dateFormat = "MMMM, yyyy"
        
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "N/A"
    }
    
    var currentYearDisplay: String {
        let selectedLocaleID = (try? LanguageSettings().selectedLanguage) ?? Locale.current.identifier
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: selectedLocaleID)
        formatter.dateFormat = "yyyy" // Chỉ format năm
        
        var components = DateComponents()
        components.year = selectedYear
        
        if let date = Calendar.current.date(from: components) {
            // QUAN TRỌNG: Chỉ trả về chuỗi năm đã được định dạng
            return formatter.string(from: date)
        }
        
        return "N/A"
    }
    
    // MARK: - Init
    
    init(repository: DataRepository = .shared) {
        self.repository = repository
        
        repository.transactionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                self?.allTransactions = transactions
                self?.updateAllCalculations()
            }
            .store(in: &cancellables)

        // Đảm bảo khi selectedYear/selectedMonth thay đổi, UI cũng cập nhật
        Publishers.CombineLatest3($periodSelection, $selectedMonth, $selectedYear)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.objectWillChange.send()
                self?.updateAllCalculations()
            }
            .store(in: &cancellables)
        refreshData()
    }

    // MARK: - Public Functions
    
    func refreshData() {
        repository.fetchTransactions()
    }
    
    func goToPreviousPeriod() {
        if periodSelection == 0 {
            selectedMonth -= 1
            if selectedMonth < 1 {
                selectedMonth = 12
                selectedYear -= 1
            }
        } else {
            selectedYear -= 1
        }
    }
    
    func goToNextPeriod() {
        if periodSelection == 0 {
            selectedMonth += 1
            if selectedMonth > 12 {
                selectedMonth = 1
                selectedYear += 1
            }
        } else {
            selectedYear += 1
        }
    }

    // MARK: - Core Logic
    
    private func updateAllCalculations() {
        // Force UI update bằng cách gọi objectWillChange trước
        objectWillChange.send()
        
        self.monthlyTransactions = filterTransactions(month: selectedMonth, year: selectedYear)
        self.yearlyTransactions = filterTransactions(year: selectedYear)
        
        // Helper function để validate và sum amounts
        // Lưu ý: amount luôn >= 0 trong database (expense và income đều là số dương)
        func safeSum(_ transactions: [Transaction]) -> Double {
            var total: Double = 0.0
            for transaction in transactions {
                let amount = transaction.amount
                // Chỉ validate isFinite và !isNaN
                if amount.isFinite && !amount.isNaN {
                    total += amount
                }
            }
            // Validate kết quả cuối cùng
            return total.isFinite && !total.isNaN ? total : 0.0
        }
        
        let monthlyExpenses = monthlyTransactions.filter { $0.type == "expense" }
        let monthlyIncomes = monthlyTransactions.filter { $0.type == "income" }
        
        // Debug logging
        print("📊 Dashboard Update - Month: \(selectedMonth)/\(selectedYear)")
        print("   Total monthly transactions: \(monthlyTransactions.count)")
        print("   Monthly expenses count: \(monthlyExpenses.count)")
        print("   Monthly incomes count: \(monthlyIncomes.count)")
        
        if !monthlyExpenses.isEmpty {
            print("   Expense amounts: \(monthlyExpenses.map { $0.amount })")
        }
        
        let newTotalMonthlyIncome = safeSum(monthlyIncomes)
        let newTotalMonthlyExpense = safeSum(monthlyExpenses)
        let newNetMonthlyBalance = newTotalMonthlyIncome - newTotalMonthlyExpense
        
        print("   Total monthly expense: \(newTotalMonthlyExpense)")
        print("   Total monthly income: \(newTotalMonthlyIncome)")

        let yearlyExpenses = yearlyTransactions.filter { $0.type == "expense" }
        let yearlyIncomes = yearlyTransactions.filter { $0.type == "income" }
        
        let newTotalYearlyIncome = safeSum(yearlyIncomes)
        let newTotalYearlyExpense = safeSum(yearlyExpenses)
        let newNetYearlyBalance = newTotalYearlyIncome - newTotalYearlyExpense

        // Update tất cả properties cùng lúc để trigger UI update
        // Đảm bảo update trên main thread (đã được đảm bảo bởi receive(on: DispatchQueue.main))
        self.totalMonthlyIncome = newTotalMonthlyIncome
        self.totalMonthlyExpense = newTotalMonthlyExpense
        self.netMonthlyBalance = newNetMonthlyBalance
        
        self.totalYearlyIncome = newTotalYearlyIncome
        self.totalYearlyExpense = newTotalYearlyExpense
        self.netYearlyBalance = newNetYearlyBalance
        
        self.monthlyExpensePieData = calculatePieData(from: monthlyExpenses, totalAmount: newTotalMonthlyExpense)
        self.monthlyIncomePieData = calculatePieData(from: monthlyIncomes, totalAmount: newTotalMonthlyIncome)
        
        self.yearlyExpensePieData = calculatePieData(from: yearlyExpenses, totalAmount: newTotalYearlyExpense)
        self.yearlyIncomePieData = calculatePieData(from: yearlyIncomes, totalAmount: newTotalYearlyIncome)
        
        print("   ✅ Updated UI - Expense: \(self.totalMonthlyExpense), Income: \(self.totalMonthlyIncome)")
        print("   Pie data count: \(self.monthlyExpensePieData.count)")
        if !self.monthlyExpensePieData.isEmpty {
            print("   Pie data totals: \(self.monthlyExpensePieData.map { $0.total })")
        }
    }
    
    private func filterTransactions(month: Int? = nil, year: Int) -> [Transaction] {
        let calendar = Calendar.current
        
        if let month = month {
            // Filter theo tháng
            let filtered = allTransactions.filter { transaction in
                guard let date = transaction.date else { return false }
                // So sánh date components để tránh vấn đề timezone
                let dateComponents = calendar.dateComponents([.year, .month], from: date)
                return dateComponents.year == year && dateComponents.month == month
            }
            
            // Debug logging
            print("🔍 Filter transactions for \(month)/\(year):")
            print("   All transactions count: \(allTransactions.count)")
            print("   Filtered count: \(filtered.count)")
            if !filtered.isEmpty {
                print("   Filtered transaction types: \(filtered.map { $0.type ?? "nil" })")
                print("   Filtered transaction amounts: \(filtered.map { $0.amount })")
            }
            
            return filtered
        } else {
            // Filter theo năm
            let filtered = allTransactions.filter { transaction in
                guard let date = transaction.date else { return false }
                // So sánh date components để tránh vấn đề timezone
                let dateComponents = calendar.dateComponents([.year], from: date)
                return dateComponents.year == year
            }
            
            return filtered
        }
    }
    
    private func calculatePieData(from transactions: [Transaction], totalAmount: Double) -> [CategorySummary] {
        
        let grouped = Dictionary(grouping: transactions) { $0.category }

        let summaries = grouped.map { (category, transactions) -> CategorySummary in
            let name = category?.name ?? "Khác"
            let iconName = category?.iconName ?? "questionmark.circle.fill"
            
            let color = IconProvider.color(for: iconName)
            
            // Validate và filter các amount không hợp lệ
            let validAmounts = transactions.compactMap { transaction -> Double? in
                let amount = transaction.amount
                return amount.isFinite && !amount.isNaN && amount >= 0 ? amount : nil
            }
            let total = validAmounts.reduce(0, +)
            
            // Validate totalAmount và total trước khi tính percentage
            let safeTotalAmount = totalAmount.isFinite && !totalAmount.isNaN && totalAmount > 0 ? totalAmount : 0
            let safeTotal = total.isFinite && !total.isNaN && total >= 0 ? total : 0
            let percentage = safeTotalAmount > 0 ? (safeTotal / safeTotalAmount) : 0.0
            
            // Validate percentage trước khi trả về
            let safePercentage = percentage.isFinite && !percentage.isNaN && percentage >= 0 ? min(percentage, 1.0) : 0.0
            
            return CategorySummary(
                name: name,
                total: safeTotal,
                percentage: safePercentage,
                iconName: iconName,
                color: color
            )
        }
        
        return summaries.sorted { $0.total > $1.total }
    }
}
