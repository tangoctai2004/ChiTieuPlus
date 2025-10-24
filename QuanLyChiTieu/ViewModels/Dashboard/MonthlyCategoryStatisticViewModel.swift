//
//  MonthlyCategoryStatisticViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 23/10/25.
//

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
    
    // MARK: - Published Properties
    @Published var monthlyChartData: [ChartDataPoint] = []
    @Published var selectedChartMonth: Int?
    @Published var displayedTransactions: [Transaction] = []
    @Published var groupedDisplayedTransactions: [GroupedTransactions] = []

    // MARK: - Read-only Properties
    let categoryName: String
    let categoryColor: Color
    let initialMonthLabel: String
    
    // MARK: - Thuộc tính mới cho Navigation Title
    var selectedPeriodString: String {
        let month = selectedChartMonth ?? initialSelectedMonth
        let year = selectedYear
        return "Tháng \(month)/\(year)"
    }

    // MARK: - Private Properties
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    
    private var allTransactionsForYear: [Transaction] = []
    
    private let selectedYear: Int
    private let initialSelectedMonth: Int
    private let categoryToFilter: String
    
    private let headerFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    // MARK: - Init
    
    init(
        categorySummary: CategorySummary,
        selectedMonth: Int,
        selectedYear: Int,
        repository: DataRepository = .shared
    ) {
        self.categoryName = categorySummary.name
        self.categoryColor = categorySummary.color
        self.categoryToFilter = categorySummary.name // Dùng tên để lọc
        
        self.selectedYear = selectedYear
        self.initialSelectedMonth = selectedMonth
        
        self.repository = repository
        
        self.initialMonthLabel = "T\(initialSelectedMonth)"
        self.selectedChartMonth = initialSelectedMonth
        
        self.monthlyChartData = (1...12).map {
            ChartDataPoint(month: $0, monthLabel: "T\($0)", totalAmount: 0)
        }

        subscribeToRepository()
        
        repository.fetchTransactions()
    }
    
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
        
        var newChartData = (1...12).map {
            ChartDataPoint(month: $0, monthLabel: "T\($0)", totalAmount: 0)
        }
        
        for transaction in self.allTransactionsForYear {
            guard let date = transaction.date else { continue }
            let month = Calendar.current.component(.month, from: date)
            newChartData[month - 1].totalAmount += (transaction.amount.isNaN ? 0 : transaction.amount)
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
        }.sorted(by: { $0.date > $1.date }) // Sắp xếp các ngày mới nhất lên đầu
    }
    
    var displayedTransactionsTotal: Double {
        displayedTransactions.reduce(0) { $0 + ($1.amount.isNaN ? 0 : $1.amount) }
    }

    // MARK: - View Helpers
    
    func formattedSectionHeaderDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Hôm nay"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Hôm qua"
        }
        return headerFormatter.string(from: date)
    }
}
