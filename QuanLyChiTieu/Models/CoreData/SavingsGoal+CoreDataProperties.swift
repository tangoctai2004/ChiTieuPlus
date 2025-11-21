//
//  SavingsGoal+CoreDataProperties.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//
//

import Foundation
import CoreData

extension SavingsGoal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavingsGoal> {
        return NSFetchRequest<SavingsGoal>(entityName: "SavingsGoal")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var targetAmount: Double
    @NSManaged public var currentAmount: Double
    @NSManaged public var startDate: Date?
    @NSManaged public var targetDate: Date?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createAt: Date?
    @NSManaged public var updateAt: Date?
    @NSManaged public var iconName: String?
    @NSManaged public var color: String?
}

extension SavingsGoal : Identifiable {
    public var progress: Double {
        if isCompleted {
            return 1.0
        }
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }
    
    public var remainingAmount: Double {
        return max(targetAmount - currentAmount, 0)
    }
    
    public var daysRemaining: Int? {
        guard let targetDate = targetDate else { return nil }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: targetDate)
        let components = calendar.dateComponents([.day], from: today, to: target)
        return components.day
    }
    
    public var isOverdue: Bool {
        guard let targetDate = targetDate else { return false }
        return Date() > targetDate && !isCompleted
    }
    
    public var hasCompletedTransaction: Bool {
        return DataRepository.shared.hasCompletedTransaction(for: self)
    }
}


