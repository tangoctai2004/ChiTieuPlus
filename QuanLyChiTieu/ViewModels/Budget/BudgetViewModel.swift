//
//  BudgetViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import Foundation
import SwiftUI
import Combine

class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var isLoading = false
    
    private let repository = DataRepository.shared
    
    init() {
        loadBudgets()
        updateAllBudgetsSpentAmount()
    }
    
    func loadBudgets() {
        isLoading = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.budgets = self.repository.fetchBudgets()
            self.isLoading = false
        }
    }
    
    func updateAllBudgetsSpentAmount() {
        // Update period for expired budgets
        repository.updateBudgetPeriods()
        
        // Reload budgets to get latest data
        loadBudgets()
    }
    
    func addBudget(
        categoryID: UUID?,
        amount: Double,
        period: BudgetPeriod,
        rolloverEnabled: Bool = false,
        warningThresholds: [Int] = [80, 90, 100]
    ) {
        repository.addBudget(
            categoryID: categoryID,
            amount: amount,
            period: period,
            rolloverEnabled: rolloverEnabled,
            warningThresholds: warningThresholds
        )
        loadBudgets()
    }
    
    func updateBudget(
        _ budget: Budget,
        amount: Double? = nil,
        period: BudgetPeriod? = nil,
        rolloverEnabled: Bool? = nil,
        warningThresholds: [Int]? = nil
    ) {
        repository.updateBudget(
            budget,
            amount: amount,
            period: period,
            rolloverEnabled: rolloverEnabled,
            warningThresholds: warningThresholds
        )
        loadBudgets()
    }
    
    func deleteBudget(_ budget: Budget) {
        repository.deleteBudget(budget)
        loadBudgets()
    }
    
    func toggleBudgetActive(_ budget: Budget) {
        repository.toggleBudgetActive(budget)
        loadBudgets()
    }
    
    var activeBudgets: [Budget] {
        budgets.filter { $0.isActive }
    }
    
    var exceededBudgets: [Budget] {
        activeBudgets.filter { $0.usagePercentage >= 1.0 }
    }
    
    var warningBudgets: [Budget] {
        activeBudgets.filter { budget in
            let percentage = budget.usagePercentage * 100
            let thresholds = budget.parsedWarningThresholds
            return percentage >= Double(thresholds[0]) && percentage < 100
        }
    }
}

