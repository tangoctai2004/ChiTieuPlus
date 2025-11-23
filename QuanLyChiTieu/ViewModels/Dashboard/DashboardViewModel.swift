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
        self.monthlyTransactions = filterTransactions(month: selectedMonth, year: selectedYear)
        self.yearlyTransactions = filterTransactions(year: selectedYear)
        
        // Helper function để validate và sum amounts
        func safeSum(_ transactions: [Transaction]) -> Double {
            transactions.compactMap { transaction -> Double? in
                let amount = transaction.amount
                return amount.isFinite && !amount.isNaN && amount >= 0 ? amount : nil
            }.reduce(0, +)
        }
        
        self.totalMonthlyIncome = safeSum(monthlyTransactions.filter { $0.type == "income" })
        self.totalMonthlyExpense = safeSum(monthlyTransactions.filter { $0.type == "expense" })
        self.netMonthlyBalance = self.totalMonthlyIncome - self.totalMonthlyExpense

        self.totalYearlyIncome = safeSum(yearlyTransactions.filter { $0.type == "income" })
        self.totalYearlyExpense = safeSum(yearlyTransactions.filter { $0.type == "expense" })
        self.netYearlyBalance = self.totalYearlyIncome - self.totalYearlyExpense

        self.monthlyExpensePieData = calculatePieData(from: monthlyTransactions.filter { $0.type == "expense" }, totalAmount: self.totalMonthlyExpense)
        self.monthlyIncomePieData = calculatePieData(from: monthlyTransactions.filter { $0.type == "income" }, totalAmount: self.totalMonthlyIncome)
        
        self.yearlyExpensePieData = calculatePieData(from: yearlyTransactions.filter { $0.type == "expense" }, totalAmount: self.totalYearlyExpense)
        self.yearlyIncomePieData = calculatePieData(from: yearlyTransactions.filter { $0.type == "income" }, totalAmount: self.totalYearlyIncome)
    }
    
    private func filterTransactions(month: Int? = nil, year: Int) -> [Transaction] {
        var components = DateComponents()
        components.year = year
        
        if let month = month {
            components.month = month
            guard let startOfMonth = Calendar.current.date(from: components),
                  let endOfMonth = Calendar.current.date(byAdding: .month, value: 1, to: startOfMonth) else { return [] }
            
            return allTransactions.filter {
                guard let date = $0.date else { return false }
                return date >= startOfMonth && date < endOfMonth
            }
        } else {
            guard let startOfYear = Calendar.current.date(from: components),
                  let endOfYear = Calendar.current.date(byAdding: .year, value: 1, to: startOfYear) else { return [] }
            
            return allTransactions.filter {
                guard let date = $0.date else { return false }
                return date >= startOfYear && date < endOfYear
            }
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
            let percentage = safeTotalAmount > 0 ? (total / safeTotalAmount) : 0.0
            
            return CategorySummary(
                name: name,
                total: total,
                percentage: percentage,
                iconName: iconName,
                color: color
            )
        }
        
        return summaries.sorted { $0.total > $1.total }
    }
}
