//
//  HomeScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 26/9/25.
//

import SwiftUI
import CoreData

// MARK: - Gradient Text Modifier
extension View {
    func gradientText(colors: [Color]) -> some View {
        self.overlay(
            LinearGradient(
                colors: colors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .mask(self)
    }
}

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: transaction.type == "income"
                                ? [Color.green.opacity(0.5), Color.green]
                                : [Color.red.opacity(0.5), Color.red],
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
                .fill(Color(.systemGray6)) // nền thẻ thay vì trắng
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - HomeScreen
struct HomeScreen: View {
    @Environment(\.managedObjectContext) private var context
    @State private var groupedTransactions: [(date: Date, items: [Transaction])] = []
    @State private var allTransactions: [Transaction] = []
    @State private var refreshId = UUID()
    
    enum FilterType: String, CaseIterable {
        case all = "Tất cả"
        case income = "Thu nhập"
        case expense = "Chi tiêu"
    }
    @State private var selectedFilter: FilterType = .all
    
    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Nền tổng thể dịu mắt
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    // ✅ App title
                    Text("ChiTiêu+")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .gradientText(colors: [.yellow, .orange, .green])
                        .padding(.top, 10)
                    
                    // ✅ Toggle
                    Picker("", selection: $selectedFilter) {
                        ForEach(FilterType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // ✅ Nội dung chính
                    if filteredTransactions().isEmpty {
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
                                ForEach(groupedFilteredTransactions(), id: \.date) { group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(formattedDate(group.date))
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
                                            .padding(.leading, 8)
                                        
                                        ForEach(group.items, id: \.id) { transaction in
                                            TransactionRow(transaction: transaction)
                                        }
                                    }
                                }
                            }
                            .id(refreshId)
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        }
                    }
                }
            }
            .onAppear {
                fetchTransactions()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Filtering
    private func filteredTransactions() -> [Transaction] {
        switch selectedFilter {
        case .all:
            return allTransactions
        case .income:
            return allTransactions.filter { $0.type == "income" }
        case .expense:
            return allTransactions.filter { $0.type == "expense" }
        }
    }
    
    private func groupedFilteredTransactions() -> [(date: Date, items: [Transaction])] {
        let filtered = filteredTransactions()
        let groupDict = Dictionary(grouping: filtered) { transaction in
            Calendar.current.startOfDay(for: transaction.date ?? Date())
        }
        let groupArray = groupDict.map { (key, value) in
            (date: key, items: value.sorted { ($0.date ?? Date()) > ($1.date ?? Date()) })
        }.sorted { $0.date > $1.date }
        return groupArray
    }
    
    private func fetchTransactions() {
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        
        do {
            let transactions = try context.fetch(request)
            allTransactions = transactions
            groupedTransactions = groupedFilteredTransactions()
            refreshId = UUID()
        } catch {
            print("Lỗi khi fetch Transaction: \(error)")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"  // ✅ định dạng mới
        return formatter.string(from: date)
    }
}
