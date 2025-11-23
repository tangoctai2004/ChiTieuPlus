//
//  WeekStartSettings.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 25/11/25.
//

import SwiftUI
import Foundation

enum WeekStartDay: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Self { self }
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .sunday:
            return "week_start_sunday"
        case .monday:
            return "week_start_monday"
        case .tuesday:
            return "week_start_tuesday"
        case .wednesday:
            return "week_start_wednesday"
        case .thursday:
            return "week_start_thursday"
        case .friday:
            return "week_start_friday"
        case .saturday:
            return "week_start_saturday"
        }
    }
    
    // Trả về Calendar.Component.weekday tương ứng
    var calendarWeekday: Int {
        return self.rawValue
    }
}

class WeekStartSettings: ObservableObject {
    static let shared = WeekStartSettings()
    
    @AppStorage("weekStartDay") var weekStartDayRaw: Int = WeekStartDay.monday.rawValue
    
    var currentWeekStartDay: WeekStartDay {
        WeekStartDay(rawValue: weekStartDayRaw) ?? .monday
    }
    
    private init() {}
    
    // Lấy ngày đầu tuần dựa trên ngày hiện tại
    func startOfWeek(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday], from: date)
        
        // Calendar weekday: 1=Sunday, 2=Monday, ..., 7=Saturday
        // WeekStartDay rawValue: 1=Sunday, 2=Monday, ..., 7=Saturday
        components.weekday = currentWeekStartDay.rawValue
        
        return calendar.date(from: components) ?? date
    }
    
    // Tính ngày tiếp theo của tuần (7 ngày sau ngày bắt đầu tuần hiện tại)
    func nextWeekStart(from date: Date = Date()) -> Date {
        let currentWeekStart = startOfWeek(for: date)
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 7, to: currentWeekStart) ?? date
    }
    
    // Tính số tuần giữa 2 ngày (theo ngày bắt đầu tuần đã chọn)
    func weeksBetween(_ startDate: Date, and endDate: Date) -> Int {
        let calendar = Calendar.current
        let startWeekStart = startOfWeek(for: startDate)
        let endWeekStart = startOfWeek(for: endDate)
        
        let days = calendar.dateComponents([.day], from: startWeekStart, to: endWeekStart).day ?? 0
        return days / 7
    }
    
    // Thêm số tuần vào một ngày (theo logic tuần đã chọn)
    // Logic: Giữ nguyên vị trí trong tuần (ví dụ: nếu là thứ 3, thì tuần sau cũng là thứ 3)
    func addWeeks(_ weeks: Int, to date: Date) -> Date {
        let calendar = Calendar.current
        let weekStart = startOfWeek(for: date)
        
        // Tính số ngày từ đầu tuần đến date hiện tại
        let daysFromWeekStart = calendar.dateComponents([.day], from: weekStart, to: date).day ?? 0
        
        // Tính ngày bắt đầu tuần mới (sau N tuần)
        let targetWeekStart = calendar.date(byAdding: .day, value: weeks * 7, to: weekStart) ?? date
        
        // Trả về ngày tương ứng trong tuần mới (giữ nguyên vị trí trong tuần)
        return calendar.date(byAdding: .day, value: daysFromWeekStart, to: targetWeekStart) ?? date
    }
}

