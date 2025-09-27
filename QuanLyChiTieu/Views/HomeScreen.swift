//
//  HomeScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 26/9/25.
//

import SwiftUI
import CoreData

// MARK: - Summary Header
struct SummaryHeaderView: View {
    let transactions: [Transaction]
    
    private var totalExpense: Double {
        transactions
            .filter { $0.type == "expense" }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        transactions
            .filter { $0.type == "income" }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var incomeCount: Int {
        transactions.filter { $0.type == "income" }.count
    }
    
    private var expenseCount: Int {
        transactions.filter { $0.type == "expense" }.count
    }
    
    var body: some View {
    }
}

// MARK: - Transaction Section
struct TransactionSection: View {
    let date: Date
    let transactions: [Transaction]
    let onUpdate: () -> Void
    
    var body: some View {
        Section(
            header:
                Text(formattedDate(date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
        ) {
            ForEach(transactions, id: \.id) { transaction in
                NavigationLink(
                    destination: TransactionDetailScreen(transaction: transaction, onUpdate: onUpdate)
                ) {
                    TransactionRow(transaction: transaction)
                        .listRowInsets(EdgeInsets())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon danh mục
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: transaction.type == "income"
                                ? [Color.green.opacity(0.3), Color.green.opacity(0.6)]
                                : [Color.red.opacity(0.3), Color.red.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: transaction.type == "income" ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.title ?? "Không tên")
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(transaction.category?.name ?? "Danh mục")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(AppUtils.formattedCurrency(transaction.amount))
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(transaction.type == "income" ? .green : .red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
        )
        .contentShape(Rectangle())
    }
}

struct HomeScreen: View {
    @Environment(\.managedObjectContext) private var context
    @State private var groupedTransactions: [(date: Date, items: [Transaction])] = []
    @State private var allTransactions: [Transaction] = []
    @State private var refreshId = UUID()
    
    // Bộ lọc ngày
    @State private var startDate: Date = Calendar.current.date(
        from: DateComponents(year: Calendar.current.component(.year, from: Date()), month: 1, day: 1)
    ) ?? Date()
    @State private var endDate: Date = Date()
    
    var body: some View {
        NavigationStack {
            VStack {
                // ✅ Thanh lọc + Refresh
                VStack(spacing: 10) {
                    HStack {
                        DatePicker("Từ ngày", selection: $startDate, displayedComponents: .date)
                        DatePicker("Đến ngày", selection: $endDate, displayedComponents: .date)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            fetchGroupTransactions()
                        }) {
                            Text("Lọc giao dịch")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // Reset ngày về mặc định
                            startDate = Calendar.current.date(
                                from: DateComponents(
                                    year: Calendar.current.component(.year, from: Date()),
                                    month: 1,
                                    day: 1
                                )
                            ) ?? Date()
                            endDate = Date()
                            
                            fetchGroupTransactions()
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.top, 10)
                
                // ✅ Nội dung chính
                if groupedTransactions.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Chưa có giao dịch")
                            .foregroundColor(.secondary)
                            .font(.headline)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // ✅ Tổng hợp
                            SummaryHeaderView(transactions: allTransactions)
                            
                            // ✅ Danh sách
                            ForEach(groupedTransactions, id: \.date) { group in
                                TransactionSection(date: group.date, transactions: group.items) {
                                    fetchGroupTransactions()
                                }
                            }
                        }
                        .id(refreshId)
                        .padding(.horizontal)
                    }
                }
            }
            .onAppear {
                fetchGroupTransactions()
            }
            .navigationTitle("ChiTiêu+")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func fetchGroupTransactions() {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        
        do {
            let transactions = try context.fetch(request)
            allTransactions = transactions
            
            let groupDict = Dictionary(grouping: transactions) { transaction in
                Calendar.current.startOfDay(for: transaction.date ?? Date())
            }
            let groupArray = groupDict.map { (key, value) in
                (date: key, items: value.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) })
            }.sorted { $0.date > $1.date }
            
            groupedTransactions = groupArray
            refreshId = UUID()
        } catch {
            print("Lỗi khi fetch Transaction: \(error)")
        }
    }
}
