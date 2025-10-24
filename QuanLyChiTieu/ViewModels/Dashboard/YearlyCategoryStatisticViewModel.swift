//
//  YearlyCategoryStatisticViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 24/10/25.
//

import Foundation
import Combine
import CoreData
import SwiftUI

class YearlyCategoryStatisticViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var monthlyChartData: [ChartDataPoint] = []
    @Published var totalYearlyAmount: Double = 0
    @Published var averageMonthlyAmount: Double = 0

    // MARK: - Read-only Properties
    let categoryName: String
    let categoryColor: Color
    let selectedYear: Int
    
    // (MỚI) Lưu lại categorySummary để dùng cho điều hướng
    let categorySummary: CategorySummary

    // MARK: - Private Properties
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    private var allTransactionsForYear: [Transaction] = []
    private let categoryToFilter: String
    
    init(
        categorySummary: CategorySummary,
        selectedYear: Int,
        repository: DataRepository = .shared
    ) {
        self.categorySummary = categorySummary // <-- (MỚI) Lưu lại
        self.categoryName = categorySummary.name
        self.categoryColor = categorySummary.color
        self.categoryToFilter = categorySummary.name
        self.selectedYear = selectedYear
        self.repository = repository
        
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
        
        // 1. Lọc
        var components = DateComponents()
        components.year = self.selectedYear
        guard let startOfYear = Calendar.current.date(from: components),
              let endOfYear = Calendar.current.date(byAdding: .year, value: 1, to: startOfYear) else { return }

        self.allTransactionsForYear = allTransactions.filter {
            guard let date = $0.date else { return false }
            let txCategoryName = $0.category?.name ?? "Khác"
            return date >= startOfYear && date < endOfYear && txCategoryName == self.categoryToFilter
        }
        
        // 2. Tính toán biểu đồ
        var newChartData = (1...12).map {
            ChartDataPoint(month: $0, monthLabel: "T\($0)", totalAmount: 0)
        }
        
        for transaction in self.allTransactionsForYear {
            guard let date = transaction.date else { continue }
            let month = Calendar.current.component(.month, from: date)
            let amount = (transaction.amount.isNaN || transaction.amount.isInfinite) ? 0 : transaction.amount
            newChartData[month - 1].totalAmount += amount
        }
        
        self.monthlyChartData = newChartData
        
        // 3. Tính toán tổng
        let total = newChartData.reduce(0) { $0 + $1.totalAmount }
        self.totalYearlyAmount = total
        self.averageMonthlyAmount = total / 12.0
    }
}
