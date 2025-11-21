//
//  CSVService.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 25/10/25.
//

import Foundation
import CoreData

// MARK: - Error Types
enum CSVError: LocalizedError {
    case noDataToExport
    case cannotAccessFile
    case invalidEncoding
    case importFailed(String)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .noDataToExport:
            return "Không có dữ liệu để xuất"
        case .cannotAccessFile:
            return "Không thể truy cập file"
        case .invalidEncoding:
            return "File không đúng định dạng"
        case .importFailed(let message):
            return "Lỗi khi nhập dữ liệu: \(message)"
        case .unknownError:
            return "Đã xảy ra lỗi không xác định"
        }
    }
}

// MARK: - Import Result
struct ImportResult {
    let added: Int
    let skipped: Int
    let errors: [String]
}

class CSVService {
    
    static let shared = CSVService()
    private let repository = DataRepository.shared
    
    // MARK: - Export Logic (CẢI THIỆN)
    
    func saveTransactionsToCSV() throws -> URL? {
        let transactions = repository.transactionsPublisher.value
        guard !transactions.isEmpty else {
            throw CSVError.noDataToExport
        }
        
        let csvString = generateCSVString(from: transactions)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        // Tên file an toàn hơn, không có ký tự đặc biệt
        let fileName = "ChiTieuPlus_\(dateString).csv"
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Xóa file cũ nếu tồn tại
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        print("✅ Đã lưu CSV tại: \(fileURL.path)")
        
        return fileURL
    }
    
    private func generateCSVString(from transactions: [Transaction]) -> String {
        // Header với BOM UTF-8 để Excel hiển thị đúng tiếng Việt
        var csvText = "\u{FEFF}Date,Title,Amount,Type,CategoryKey,Note\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Sắp xếp theo ngày giảm dần để dễ đọc
        let sortedTransactions = transactions.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) }
        
        for tx in sortedTransactions {
            let date = dateFormatter.string(from: tx.date ?? Date())
            let categoryKey = escapeCSVField(tx.category?.name ?? "common_no_name")
            let title = escapeCSVField(tx.title ?? "")
            let note = escapeCSVField(tx.note ?? "")
            let type = escapeCSVField(tx.type ?? "expense")
            
            // Dùng String(format:) với locale en_US để đảm bảo dấu chấm thập phân
            let amount = String(format: "%.2f", tx.amount)
            
            let row = "\(date),\(title),\(amount),\(type),\(categoryKey),\(note)\n"
            csvText.append(row)
        }
        return csvText
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\n") || field.contains("\"") {
            let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escapedField)\""
        } else {
            return field
        }
    }
    

    // MARK: - Import Logic (CẢI THIỆN)
    
    func parseAndImport(url: URL, completion: @escaping (Result<ImportResult, CSVError>) -> Void) {
        let container = CoreDataStack.shared.container
        container.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.failure(.unknownError))
                }
                return
            }
            
            guard url.startAccessingSecurityScopedResource() else {
                DispatchQueue.main.async {
                    completion(.failure(.cannotAccessFile))
                }
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                // Thử đọc với UTF-8, nếu thất bại thử UTF-16
                var csvData: String
                if let data = try? String(contentsOf: url, encoding: .utf8) {
                    csvData = data
                } else if let data = try? String(contentsOf: url, encoding: .utf16) {
                    csvData = data
                } else {
                    throw CSVError.invalidEncoding
                }
                
                // Loại bỏ BOM nếu có
                if csvData.hasPrefix("\u{FEFF}") {
                    csvData = String(csvData.dropFirst())
                }
                
                let request: NSFetchRequest<Category> = Category.fetchRequest()
                let allCategories = try backgroundContext.fetch(request)
                print("✅ Đã tải \(allCategories.count) category trên luồng nền.")
                
                let rows = csvData.components(separatedBy: CharacterSet.newlines)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                
                var transactionsAdded = 0
                var transactionsSkipped = 0
                var errors: [String] = []
                
                // Lấy tất cả transaction hiện có để kiểm tra duplicate
                let existingRequest: NSFetchRequest<Transaction> = Transaction.fetchRequest()
                let existingTransactions = try backgroundContext.fetch(existingRequest)
                // Tạo set để kiểm tra duplicate dựa trên date, amount, type
                let existingSet = Set(existingTransactions.compactMap { tx -> String? in
                    guard let date = tx.date else { return nil }
                    let dateStr = dateFormatter.string(from: date)
                    // Làm tròn amount để so sánh (tránh lỗi floating point)
                    let roundedAmount = String(format: "%.2f", tx.amount)
                    return "\(dateStr)_\(roundedAmount)_\(tx.type ?? "")"
                })
                
                for (index, row) in rows.enumerated() {
                    let rowNumber = index + 1
                    if row.isEmpty || row.trimmingCharacters(in: .whitespaces).isEmpty { continue }
                    if index == 0 && row.contains("Date") { continue } // Skip header
                    
                    let columns = self.splitCSVRow(row)
                    guard columns.count >= 6 else {
                        errors.append("Dòng \(rowNumber): Thiếu cột dữ liệu")
                        transactionsSkipped += 1
                        continue
                    }
                    
                    // Date,Title,Amount,Type,CategoryKey,Note
                    let dateString = columns[0]
                    let title = columns[1]
                    let amountString = columns[2]
                    let type = columns[3]
                    let categoryKey = columns[4]
                    let note = columns[5]
                    
                    // Validate date
                    guard let date = dateFormatter.date(from: dateString) else {
                        errors.append("Dòng \(rowNumber): Ngày không hợp lệ: \(dateString)")
                        transactionsSkipped += 1
                        continue
                    }
                    
                    // Validate amount
                    guard let amount = Double(amountString), amount > 0 else {
                        errors.append("Dòng \(rowNumber): Số tiền không hợp lệ: \(amountString)")
                        transactionsSkipped += 1
                        continue
                    }
                    
                    // Validate type
                    guard type == "income" || type == "expense" else {
                        errors.append("Dòng \(rowNumber): Loại giao dịch không hợp lệ: \(type)")
                        transactionsSkipped += 1
                        continue
                    }
                    
                    // Kiểm tra duplicate (dựa trên date, amount, type)
                    let roundedAmount = String(format: "%.2f", amount)
                    let transactionKey = "\(dateFormatter.string(from: date))_\(roundedAmount)_\(type)"
                    if existingSet.contains(transactionKey) {
                        transactionsSkipped += 1
                        continue // Skip duplicate
                    }
                    
                    let categoryInContext = allCategories.first(where: { $0.name == categoryKey })
                    
                    let newTransaction = Transaction(context: backgroundContext)
                    newTransaction.id = UUID()
                    newTransaction.date = date
                    newTransaction.amount = amount
                    newTransaction.type = type
                    newTransaction.note = note
                    newTransaction.category = categoryInContext
                    newTransaction.title = title.isEmpty ? (categoryInContext?.name ?? "common_category") : title
                    newTransaction.createAt = Date()
                    newTransaction.updateAt = Date()
                    
                    transactionsAdded += 1
                }
                
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                    print("✅ Đã lưu thành công \(transactionsAdded) giao dịch vào context nền.")
                    
                    DispatchQueue.main.async {
                        self.repository.fetchTransactions()
                        completion(.success(ImportResult(
                            added: transactionsAdded,
                            skipped: transactionsSkipped,
                            errors: errors
                        )))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(.success(ImportResult(
                            added: 0,
                            skipped: transactionsSkipped,
                            errors: errors
                        )))
                    }
                }
                
            } catch {
                print("❌ Lỗi khi import CSV trên luồng nền: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(.importFailed(error.localizedDescription)))
                }
            }
        }
    }
    
    // Overload để tương thích với code cũ
    func parseAndImport(url: URL) {
        parseAndImport(url: url) { result in
            switch result {
            case .success(let importResult):
                print("✅ Import thành công: \(importResult.added) giao dịch đã thêm, \(importResult.skipped) đã bỏ qua")
            case .failure(let error):
                print("❌ Import thất bại: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func splitCSVRow(_ row: String) -> [String] {
        var columns: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        columns.append(currentField)
        
        return columns.map {
            $0.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
              .replacingOccurrences(of: "\"\"", with: "\"")
        }
    }
}
