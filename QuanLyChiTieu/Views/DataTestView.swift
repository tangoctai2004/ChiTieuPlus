////
////  DataTestView.swift
////  QuanLyChiTieu
////
////  Created by Tạ Ngọc Tài on 17/10/25.
////
//
//import SwiftUI
//import CoreData
//import Combine
//
//struct DataTestView: View {
//    // State để lưu trữ dữ liệu sau khi fetch, phục vụ việc in ra console
//    @State private var categories: [Category] = []
//    @State private var transactions: [Transaction] = []
//    @State private var cancellables = Set<AnyCancellable>()
//    
//    // MARK: - Body
//    var body: some View {
//        NavigationStack {
//            List {
//                Section(header: Text("📝 Fetch & Print")) {
//                    Button("Fetch & Print Categories") {
//                        DataRepository.shared.fetchCategories()
//                    }
//                    
//                    Button("Fetch & Print Transactions") {
//                        DataRepository.shared.fetchTransactions()
//                    }
//                }
//                
//                Section(header: Text("🛠️ Data Manipulation")) {
//                    Button("Fix 'Unknown' Type Transactions") {
//                        DataRepository.shared.fixUnknownTransactions()
//                    }
//                    
//                    Button("Delete All Data") {
//                        DataRepository.shared.deleteAllData()
//                    }
//                    .foregroundColor(.red)
//                }
//            }
//            .navigationTitle("Data Test Panel")
//        }
//        .onAppear(perform: setupSubscribers)
//    }
//    
//    // MARK: - Helper Functions
//    
//    private func setupSubscribers() {
//        // Lắng nghe publisher của categories
//        DataRepository.shared.categoriesPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { fetchedCategories in
//                print("\n\n===== 🟢 CATEGORY PUBLISHER RECEIVED DATA 🟢 =====")
//                self.categories = fetchedCategories
//                printCategories(categories: fetchedCategories)
//                print("============================================\n")
//            }
//            .store(in: &cancellables)
//
//        // Lắng nghe publisher của transactions
//        DataRepository.shared.transactionsPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { fetchedTransactions in
//                print("\n\n===== 🔵 TRANSACTION PUBLISHER RECEIVED DATA 🔵 =====")
//                self.transactions = fetchedTransactions
//                printTransactions(transactions: fetchedTransactions)
//                print("===============================================\n")
//            }
//            .store(in: &cancellables)
//    }
//
//    private func printCategories(categories: [Category]) {
//        if categories.isEmpty {
//            print("🗂️ Không có dữ liệu Category!")
//        } else {
//            print("🗂️ Danh sách danh mục (\(categories.count) items):")
//            categories.forEach { category in
//                let name = category.name ?? "(Không tên)"
//                let type = category.type ?? "(unknown)"
//                let icon = category.iconName ?? "(no icon)"
//                print("   - ID: \(category.id?.uuidString.prefix(8) ?? "-"), Name: \(name), Type: \(type), Icon: \(icon)")
//            }
//        }
//    }
//    
//    // SỬA ĐỔI NẰM Ở ĐÂY
//    private func printTransactions(transactions: [Transaction]) {
//        if transactions.isEmpty {
//            print("🧾 Không có dữ liệu Transaction!")
//        } else {
//            print("🧾 Danh sách giao dịch (\(transactions.count) items):")
//            transactions.forEach { transaction in
//                let title = transaction.title ?? "(Không tên)"
//                let amount = AppUtils.formattedCurrency(transaction.amount)
//                
//                // Sử dụng hàm format date an toàn hơn
//                let date = formattedDate(transaction.date)
//                
//                let category = transaction.category?.name ?? "(Chưa phân loại)"
//                let type = transaction.type ?? "(unknown)"
//                print("   - Title: \(title), Type: \(type), Category: \(category), Amount: \(amount), Date: \(date)")
//            }
//        }
//    }
//    
//    // Hàm helper để định dạng ngày tháng
//    private func formattedDate(_ date: Date?) -> String {
//        guard let date = date else { return "(no date)" }
//        let formatter = DateFormatter()
//        formatter.dateStyle = .short
//        formatter.timeStyle = .none
//        formatter.locale = Locale(identifier: "vi_VN") // Hiển thị theo định dạng Việt Nam
//        return formatter.string(from: date)
//    }
//}
//
//#Preview {
//    DataTestView()
//}
