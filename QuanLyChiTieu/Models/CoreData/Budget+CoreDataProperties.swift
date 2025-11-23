//
//  Budget+CoreDataProperties.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import Foundation
import CoreData
import SwiftUI

extension Budget {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Budget> {
        return NSFetchRequest<Budget>(entityName: "Budget")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var categoryID: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var period: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var rolloverEnabled: Bool
    @NSManaged public var warningThresholds: String?
    @NSManaged public var createAt: Date?
    @NSManaged public var updateAt: Date?
}

extension Budget : Identifiable {
    public var budgetPeriod: BudgetPeriod {
        BudgetPeriod(rawValue: period ?? "monthly") ?? .monthly
    }
    
    public var parsedWarningThresholds: [Int] {
        guard let thresholds = warningThresholds,
              let data = thresholds.data(using: .utf8),
              let array = try? JSONDecoder().decode([Int].self, from: data) else {
            return [80, 90, 100] // Default thresholds
        }
        return array
    }
    
    public var spentAmount: Double {
        let calculated = DataRepository.shared.calculateSpentAmount(for: self)
        // Validate trước khi trả về
        return calculated.isFinite && !calculated.isNaN && calculated >= 0 ? calculated : 0
    }
    
    public var usagePercentage: Double {
        // Validate amount và spentAmount trước khi tính
        let safeAmount = amount.isFinite && !amount.isNaN && amount > 0 ? amount : 1
        let safeSpent = spentAmount.isFinite && !spentAmount.isNaN && spentAmount >= 0 ? spentAmount : 0
        
        let percentage = safeSpent / safeAmount
        // Validate kết quả
        if percentage.isFinite && !percentage.isNaN {
            return min(percentage, 1.0)
        }
        return 0
    }
    
    public var remainingAmount: Double {
        let safeAmount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
        let safeSpent = spentAmount.isFinite && !spentAmount.isNaN && spentAmount >= 0 ? spentAmount : 0
        let remaining = safeAmount - safeSpent
        return remaining.isFinite && !remaining.isNaN ? max(remaining, 0) : 0
    }
    
    public var warningStatus: BudgetWarningStatus {
        let safePercentage = usagePercentage.isFinite && !usagePercentage.isNaN ? usagePercentage : 0
        let percentage = safePercentage * 100
        
        // Validate percentage trước khi so sánh
        guard percentage.isFinite && !percentage.isNaN else {
            return .normal
        }
        
        let thresholds = parsedWarningThresholds
        
        if percentage >= 100 {
            return .exceeded
        } else if percentage >= Double(thresholds.last ?? 100) {
            return .critical
        } else if percentage >= Double(thresholds[1]) {
            return .warning
        } else if percentage >= Double(thresholds[0]) {
            return .caution
        } else {
            return .normal
        }
    }
    
    public var currentPeriodEndDate: Date? {
        guard let startDate = startDate else { return nil }
        let calendar = Calendar.current
        
        switch budgetPeriod {
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: startDate)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startDate)
        }
    }
    
    public var isPeriodExpired: Bool {
        guard let endDate = currentPeriodEndDate else { return false }
        return Date() >= endDate
    }
}

// MARK: - Enums

public enum BudgetPeriod: String, CaseIterable, Identifiable {
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"
    
    public var id: String { self.rawValue }
    
    public var localizedName: LocalizedStringKey {
        switch self {
        case .monthly: return "budget_period_monthly"
        case .quarterly: return "budget_period_quarterly"
        case .yearly: return "budget_period_yearly"
        }
    }
}

public enum BudgetWarningStatus {
    case normal      // < 80%
    case caution     // 80-89%
    case warning     // 90-99%
    case critical    // 100%
    case exceeded    // > 100%
    
    public var color: Color {
        switch self {
        case .normal: return AppColors.incomeColor
        case .caution: return .yellow
        case .warning: return .orange
        case .critical: return AppColors.expenseColor
        case .exceeded: return AppColors.expenseColor
        }
    }
}

