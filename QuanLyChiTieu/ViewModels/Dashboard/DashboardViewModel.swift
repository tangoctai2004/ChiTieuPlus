//
//  DashboardViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 23/10/25.
//

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
    
    // -- Giao dịch thô --
    @Published var monthlyTransactions: [Transaction] = []
    @Published var yearlyTransactions: [Transaction] = []
    
    // -- Thống kê tổng quan --
    @Published var totalMonthlyIncome: Double = 0
    @Published var totalMonthlyExpense: Double = 0
    @Published var netMonthlyBalance: Double = 0
    
    @Published var totalYearlyIncome: Double = 0
    @Published var totalYearlyExpense: Double = 0
    @Published var netYearlyBalance: Double = 0
    
    // -- Dữ liệu biểu đồ tròn --
    @Published var monthlyExpensePieData: [CategorySummary] = []
    @Published var monthlyIncomePieData: [CategorySummary] = []
    @Published var yearlyExpensePieData: [CategorySummary] = []
    @Published var yearlyIncomePieData: [CategorySummary] = []

    // MARK: - Private Properties
    private var allTransactions: [Transaction] = []
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Display Properties (Cho DateNavigatorView)
    
    var currentMonthDisplay: String {
        let formatter = DateFormatter()
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
        return "Năm \(String(selectedYear))"
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

        Publishers.CombineLatest3($periodSelection, $selectedMonth, $selectedYear)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _, _ in
                self?.updateAllCalculations()
            }
            .store(in: &cancellables)
        refreshData()
    }

//     MARK: - Public Functions
    
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
        
        self.totalMonthlyIncome = monthlyTransactions.filter { $0.type == "income" }.map(\.amount).reduce(0, +)
        self.totalMonthlyExpense = monthlyTransactions.filter { $0.type == "expense" }.map(\.amount).reduce(0, +)
        self.netMonthlyBalance = self.totalMonthlyIncome - self.totalMonthlyExpense

        self.totalYearlyIncome = yearlyTransactions.filter { $0.type == "income" }.map(\.amount).reduce(0, +)
        self.totalYearlyExpense = yearlyTransactions.filter { $0.type == "expense" }.map(\.amount).reduce(0, +)
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
            
            let total = transactions.map(\.amount).reduce(0, +)
            
            let percentage = (totalAmount == 0 || totalAmount.isNaN || totalAmount.isInfinite) ? 0.0 : (total / totalAmount)
            
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
