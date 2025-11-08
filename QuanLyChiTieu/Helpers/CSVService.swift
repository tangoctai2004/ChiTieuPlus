//
//  CSVService.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 25/10/25.
//

import Foundation
import CoreData // Cần để dùng DataRepository

class CSVService {
    
    static let shared = CSVService()
    private let repository = DataRepository.shared
    
    // MARK: - Export Logic
    
    /**
     Lưu tất cả giao dịch vào một file CSV trong thư mục tạm.
     Trả về URL của file đã lưu.
     */
    func saveTransactionsToCSV() throws -> URL? {
        let transactions = repository.transactionsPublisher.value
        guard !transactions.isEmpty else {
            print("Không có giao dịch để xuất.")
            return nil
        }
        
        // 1. Tạo nội dung CSV
        let csvString = generateCSVString(from: transactions)
        
        // 2. Tạo tên file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd" // MM là tháng, mm là phút
        let dateString = dateFormatter.string(from: Date())
        let fileName = "Chi Tieu Plus at \(dateString).csv"
        
        // 3. Lấy thư mục tạm
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // 4. Ghi file
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        print("Đã lưu CSV tại: \(fileURL.path)")
        
        return fileURL
    }
    
    /**
     Tạo một chuỗi String định dạng CSV từ mảng Transaction.
     */
    private func generateCSVString(from transactions: [Transaction]) -> String {
        var csvText = "Date,Title,Amount,Type,CategoryKey,Note\n" // Header
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // ISO 8601
        
        for tx in transactions {
            let date = dateFormatter.string(from: tx.date ?? Date())
            
            // Lấy KEY của category (ví dụ: "default_category_food")
            // Đây là điều RẤT QUAN TRỌNG để import lại
            let categoryKey = tx.category?.name ?? "common_no_name"
            
            let title = escapeCSVField(tx.title ?? "")
            let note = escapeCSVField(tx.note ?? "")
            let type = escapeCSVField(tx.type ?? "expense")
            let amount = "\(tx.amount)" // Số không cần escape
            
            let row = "\(date),\(title),\(amount),\(type),\(categoryKey),\(note)\n"
            csvText.append(row)
        }
        return csvText
    }
    
    /**
     "Thoát" các ký tự đặc biệt (dấu phẩy, xuống dòng) cho CSV
     bằng cách bọc chuỗi trong dấu ngoặc kép.
     */
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            // Thay thế " bằng "" và bọc toàn bộ bằng "
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        } else {
            return field // Không cần escape
        }
    }
    
    // MARK: - Import Logic (Sẽ thêm ở Phần 2)
}