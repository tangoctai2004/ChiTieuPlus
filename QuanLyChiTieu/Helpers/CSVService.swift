//
//  CSVService.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 25/10/25.
//

import Foundation
import CoreData

class CSVService {
    
    static let shared = CSVService()
    private let repository = DataRepository.shared
    
    // MARK: - Export Logic (GIỮ NGUYÊN)
    
    func saveTransactionsToCSV() throws -> URL? {
        let transactions = repository.transactionsPublisher.value
        guard !transactions.isEmpty else {
            print("Không có giao dịch để xuất.")
            return nil
        }
        
        let csvString = generateCSVString(from: transactions)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy_MM_dd"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "Chi Tieu Plus at \(dateString).csv"
        
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        print("Đã lưu CSV tại: \(fileURL.path)")
        
        return fileURL
    }
    
    private func generateCSVString(from transactions: [Transaction]) -> String {
        var csvText = "Date,Title,Amount,Type,CategoryKey,Note\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        for tx in transactions {
            let date = dateFormatter.string(from: tx.date ?? Date())
            let categoryKey = tx.category?.name ?? "common_no_name"
            let title = escapeCSVField(tx.title ?? "")
            let note = escapeCSVField(tx.note ?? "")
            let type = escapeCSVField(tx.type ?? "expense")
            
            // --- (SỬA ĐỔI 1: LÚC XUẤT FILE) ---
            // Dùng String(describing:) để đảm bảo
            // luôn dùng "." làm dấu thập phân,
            // bất kể ngôn ngữ (locale) của máy.
            // Ví dụ: "20000.0"
            let amount = String(describing: tx.amount)
            // --- (KẾT THÚC SỬA ĐỔI 1) ---
            
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
    

    // MARK: - Import Logic (ĐÃ SỬA)
    
    func parseAndImport(url: URL) {
        
        let container = CoreDataStack.shared.container
        container.performBackgroundTask { [weak self] backgroundContext in
            guard let self = self else { return }
            
            guard url.startAccessingSecurityScopedResource() else {
                print("Không thể truy cập file an toàn.")
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let csvData = try String(contentsOf: url, encoding: .utf8)
                
                let request: NSFetchRequest<Category> = Category.fetchRequest()
                let allCategories = try backgroundContext.fetch(request)
                print("Đã tải \(allCategories.count) category trên luồng nền.")
                
                let rows = csvData.components(separatedBy: "\n")
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                
                var transactionsAdded = 0
                
                for row in rows.dropFirst() {
                    if row.isEmpty { continue }
                    
                    let columns = self.splitCSVRow(row)
                    if columns.count < 6 { continue }
                    
                    let newTransaction = Transaction(context: backgroundContext)
                    
                    // Date,Title,Amount,Type,CategoryKey,Note
                    let date = dateFormatter.date(from: columns[0]) ?? Date()
                    let title = columns[1]
                    let amountString = columns[2] // Đây là string dạng "20000.0"
                    let type = columns[3]
                    let categoryKey = columns[4]
                    let note = columns[5]
                    
                    let categoryInContext = allCategories.first(where: { $0.name == categoryKey })
                    
                    newTransaction.id = UUID()
                    newTransaction.date = date
                    
                    // --- (SỬA ĐỔI 2: LÚC NHẬP FILE) ---
                    // Chuyển đổi trực tiếp từ string "20000.0" sang Double.
                    // KHÔNG dùng AppUtils.currencyToDouble, vì nó sẽ
                    // xóa dấu "." và biến "20000.0" thành 200000.0
                    newTransaction.amount = Double(amountString) ?? 0.0
                    // --- (KẾT THÚC SỬA ĐỔI 2) ---
                    
                    newTransaction.type = type
                    newTransaction.note = note
                    newTransaction.category = categoryInContext
                    
                    if title.isEmpty {
                        newTransaction.title = categoryInContext?.name ?? "common_category"
                    } else {
                        newTransaction.title = title
                    }
                    
                    newTransaction.createAt = Date()
                    newTransaction.updateAt = Date()
                    
                    transactionsAdded += 1
                }
                
                if backgroundContext.hasChanges {
                    try backgroundContext.save()
                    print("Đã lưu thành công \(transactionsAdded) giao dịch vào context nền.")
                    
                    DispatchQueue.main.async {
                        self.repository.fetchTransactions()
                    }
                } else {
                    print("Không có thay đổi nào để lưu.")
                }
                
            } catch {
                print("Lỗi khi import CSV trên luồng nền: \(error.localizedDescription)")
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
