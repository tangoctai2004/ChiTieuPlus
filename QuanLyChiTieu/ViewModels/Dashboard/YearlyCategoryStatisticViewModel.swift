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
    
    // --- (SỬA ĐỔI) ---
    // Thêm các thuộc tính mới để giữ văn bản đã được dịch
    @Published var localizedChartTitle: String = ""
    @Published var localizedCategoryName: String = ""
    @Published var localizedTotalTransactions: String = ""
    @Published var localizedMonthlyAverage: String = ""
    @Published var localizedMonthlyDetailHeader: String = ""
    // Dùng cho danh sách "Tháng 1", "Tháng 2"...
    @Published var localizedMonthPrefixes: [Int: String] = [:]
    // --- (KẾT THÚC SỬA ĐỔI) ---


    // MARK: - Read-only Properties
    let categoryName: String // Đây là KEY (ví dụ: "default_category_housing")
    let categoryColor: Color
    let selectedYear: Int
    let categorySummary: CategorySummary

    // MARK: - Private Properties
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    private var allTransactionsForYear: [Transaction] = []
    
    init(
        categorySummary: CategorySummary,
        selectedYear: Int,
        repository: DataRepository = .shared
    ) {
        self.categorySummary = categorySummary
        self.categoryName = categorySummary.name // Giữ nguyên, đây là key
        self.categoryColor = categorySummary.color
        self.selectedYear = selectedYear
        self.repository = repository
        
        // Logic getMonthLabel (cho biểu đồ) từ lần trước vẫn giữ nguyên
        self.monthlyChartData = (1...12).map { month in
            ChartDataPoint(month: month, monthLabel: getMonthLabel(for: month), totalAmount: 0)
        }

        // --- (SỬA ĐỔI) ---
        // Gọi hàm để dịch tất cả văn bản cần thiết
        updateLocalizedStrings()
        // --- (KẾT THÚC SỬA ĐỔI) ---

        subscribeToRepository()
        repository.fetchTransactions()
    }
    
    private func subscribeToRepository() {
        repository.transactionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] allTransactions in
                guard let self = self else { return }
                // Cập nhật lại logic filter để dùng key (self.categoryName)
                self.processTransactions(allTransactions: allTransactions)
            }
            .store(in: &cancellables)
    }

    // MARK: - Core Logic
    
    private func processTransactions(allTransactions: [Transaction]) {
        
        // 1. Lọc (Giữ nguyên)
        var components = DateComponents()
        components.year = self.selectedYear
        guard let startOfYear = Calendar.current.date(from: components),
              let endOfYear = Calendar.current.date(byAdding: .year, value: 1, to: startOfYear) else { return }

        self.allTransactionsForYear = allTransactions.filter {
            guard let date = $0.date else { return false }
            // Dùng self.categoryName (là key) để lọc
            let txCategoryName = $0.category?.name ?? "Khác"
            return date >= startOfYear && date < endOfYear && txCategoryName == self.categoryName
        }
        
        // 2. Tính toán biểu đồ (Giữ nguyên logic từ lần trước)
        var newChartData = (1...12).map { month in
            ChartDataPoint(month: month, monthLabel: getMonthLabel(for: month), totalAmount: 0)
        }
        
        for transaction in self.allTransactionsForYear {
            guard let date = transaction.date else { continue }
            let month = Calendar.current.component(.month, from: date)
            let amount = (transaction.amount.isNaN || transaction.amount.isInfinite) ? 0 : transaction.amount
            newChartData[month - 1].totalAmount += amount
        }
        
        self.monthlyChartData = newChartData
        
        // 3. Tính toán tổng (Validate totalAmount)
        let total = newChartData.reduce(0) { sum, dataPoint in
            let amount = dataPoint.totalAmount
            let safeAmount = amount.isFinite && !amount.isNaN && amount >= 0 ? amount : 0
            return sum + safeAmount
        }
        self.totalYearlyAmount = total
        // Validate trước khi chia
        let safeTotal = total.isFinite && !total.isNaN ? total : 0
        self.averageMonthlyAmount = safeTotal / 12.0
    }
    
    // MARK: - (HÀM MỚI) Localization Helper
    
    /**
     Đọc ngôn ngữ từ UserDefaults và tải tất cả các chuỗi văn bản đã dịch.
     */
    private func updateLocalizedStrings() {
        // 1. Lấy ngôn ngữ đã lưu của app
        let appLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "vi"
        
        // 2. Tìm đúng bundle (tệp .lproj) cho ngôn ngữ đó
        guard let path = Bundle.main.path(forResource: appLanguage, ofType: "lproj"),
              let langBundle = Bundle(path: path) else {
            print("❌ Không tìm thấy language bundle cho: \(appLanguage)")
            return
        }
        
        // 3. Dịch tất cả các chuỗi văn bản
        
        // Tiêu đề biểu đồ (có format)
        let titleFormat = langBundle.localizedString(forKey: "yearly_stats_chart_title", value: "YEAR %@ ANALYSIS CHART", table: nil)
        self.localizedChartTitle = String(format: titleFormat, String(selectedYear))
        
        // Tiêu đề Toolbar (tên category)
        self.localizedCategoryName = langBundle.localizedString(forKey: self.categoryName, value: self.categoryName, table: nil)
        
        // Box tóm tắt
        self.localizedTotalTransactions = langBundle.localizedString(forKey: "yearly_stats_total_transactions", value: "Total Transactions", table: nil)
        self.localizedMonthlyAverage = langBundle.localizedString(forKey: "yearly_stats_monthly_average", value: "Monthly Average", table: nil)
        
        // Tiêu đề danh sách
        self.localizedMonthlyDetailHeader = langBundle.localizedString(forKey: "yearly_stats_monthly_detail_header", value: "MONTHLY DETAILS", table: nil)

        // Danh sách tháng (có format)
        let monthFormat = langBundle.localizedString(forKey: "common_month_prefix", value: "Month %@", table: nil)
        var prefixes: [Int: String] = [:]
        for month in 1...12 {
            prefixes[month] = String(format: monthFormat, "\(month)")
        }
        self.localizedMonthPrefixes = prefixes
    }
    
    
    // MARK: - (HÀM CŨ) Helper Function (Giữ nguyên)
    // Hàm này dùng cho trục X của BIỂU ĐỒ ("Jan", "Feb"...)
    private func getMonthLabel(for month: Int) -> String {
        let appLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? "vi"
        
        if appLanguage == "vi" {
            // "T1", "T2", ...
            return "T\(month)"
        } else {
            // "Jan", "Feb", ...
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: appLanguage)
            
            if month >= 1 && month <= 12 {
                return formatter.shortMonthSymbols[month - 1]
            } else {
                return "T\(month)" // Fallback
            }
        }
    }
}
