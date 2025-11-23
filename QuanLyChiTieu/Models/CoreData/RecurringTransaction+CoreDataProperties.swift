//
//  RecurringTransaction+CoreDataProperties.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import Foundation
import CoreData
import SwiftUI

extension RecurringTransaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecurringTransaction> {
        return NSFetchRequest<RecurringTransaction>(entityName: "RecurringTransaction")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var amount: Double
    @NSManaged public var type: String?
    @NSManaged public var categoryID: UUID?
    @NSManaged public var frequency: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var nextDueDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var note: String?
    @NSManaged public var createAt: Date?
    @NSManaged public var updateAt: Date?
}

extension RecurringTransaction : Identifiable {
    public var transactionFrequency: RecurringFrequency {
        RecurringFrequency(rawValue: frequency ?? "monthly") ?? .monthly
    }
    
    public var isDue: Bool {
        guard let nextDueDate = nextDueDate else { return false }
        return Date() >= nextDueDate
    }
    
    public var isExpired: Bool {
        guard let endDate = endDate else { return false }
        return Date() > endDate
    }
    
    public var calculatedNextDueDate: Date? {
        guard let startDate = startDate else { return nil }
        let calendar = Calendar.current
        let now = Date()
        
        var currentDate = nextDueDate ?? startDate
        
        while currentDate <= now {
            switch transactionFrequency {
            case .daily:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .weekly:
                // Sử dụng WeekStartSettings để tính tuần theo ngày bắt đầu tuần đã chọn
                currentDate = WeekStartSettings.shared.addWeeks(1, to: currentDate)
            case .monthly:
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            case .yearly:
                currentDate = calendar.date(byAdding: .year, value: 1, to: currentDate) ?? currentDate
            }
            
            if let endDate = endDate, currentDate > endDate {
                return nil
            }
        }
        
        return currentDate
    }
}

// MARK: - Enums

public enum RecurringFrequency: String, CaseIterable, Identifiable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    public var id: String { self.rawValue }
    
    public var localizedName: LocalizedStringKey {
        switch self {
        case .daily: return "recurring_frequency_daily"
        case .weekly: return "recurring_frequency_weekly"
        case .monthly: return "recurring_frequency_monthly"
        case .yearly: return "recurring_frequency_yearly"
        }
    }
    
    public var interval: Int {
        switch self {
        case .daily: return 1
        case .weekly: return 7
        case .monthly: return 30
        case .yearly: return 365
        }
    }
}

