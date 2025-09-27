//
//  TransactionDetailScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 26/9/25.
//

import SwiftUI
import CoreData

struct TransactionDetailScreen: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var transaction: Transaction
    
    @State private var title: String = ""
    @State private var rawAmount: String = ""
    @State private var formattedAmount: String = ""
    @State private var date: Date = Date()
    @State private var selectedCategory: Category?
    @State private var selectedType: String = "expense"
    @State private var note: String = ""
    
    let onUpdate: () -> Void
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Nền đồng bộ HomeScreen
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Tiêu đề
                        TextFieldWithIcon(
                            systemName: "text.cursor",
                            placeholder: "Tiêu đề",
                            text: $title
                        )
                        
                        // Số tiền
                        HStack {
                            TextFieldWithIcon(
                                systemName: "dollarsign.circle",
                                placeholder: "Số tiền",
                                text: $formattedAmount
                            )
                            .keyboardType(.numberPad)
                            .onChange(of: formattedAmount) { newValue in
                                let digits = newValue.filter { "0123456789".contains($0) }
                                rawAmount = digits
                                formattedAmount = AppUtils.formatCurrencyInput(digits)
                            }
                            
                            Text("VNĐ")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 8)
                        }
                        
                        // Ngày giao dịch
                        LabeledContent {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                        } label: {
                            Label("Ngày giao dịch", systemImage: "calendar")
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                        
                        // Loại giao dịch
                        PickerWithStyle(
                            title: "Loại giao dịch",
                            systemImage: "arrow.left.arrow.right.circle",
                            selection: $selectedType,
                            options: AppUtils.transactionTypes.map { ($0, AppUtils.displayType($0)) }
                        )
                        
                        // Danh mục
                        PickerWithStyleCategory(
                            title: "Danh mục",
                            systemImage: "folder",
                            selection: $selectedCategory,
                            categories: categories.filter { $0.type == selectedType }
                        )
                        
                        // Ghi chú
                        TextFieldWithIcon(
                            systemName: "note.text",
                            placeholder: "Ghi chú",
                            text: $note
                        )
                        
                        // Nút lưu chỉnh sửa
                        Button(action: updateTransaction) {
                            Text("💾 Lưu chỉnh sửa")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                        }
                        .disabled(!canUpdate)
                        
                        // Nút xoá giao dịch
                        Button(role: .destructive, action: deleteTransaction) {
                            Text("🗑️ Xoá giao dịch")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                        }
                        .padding(.top, 5)
                    }
                    .padding()
                }
            }
            .navigationTitle("Chi tiết giao dịch")
            .onAppear(perform: loadData) // Load dữ liệu khi vào
        }
    }
    
    //    Load dữ liệu khi mở màn chi tiết
    private func loadData() {
        title = transaction.title ?? ""
        rawAmount = String(Int(transaction.amount))
        formattedAmount = AppUtils.formatCurrencyInput(rawAmount)
        date = transaction.date ?? Date()
        selectedType = transaction.type ?? "expense"
        selectedCategory = transaction.category
        note = transaction.note ?? ""
    }
    
    //    Kiểm tra đủ điều kiện lưu
    private var canUpdate: Bool {
        !title.isEmpty && AppUtils.currencyToDouble(rawAmount) > 0 && selectedCategory != nil
    }
    
    //    Cập nhật giao dịch
    private func updateTransaction() {
        transaction.title = title
        transaction.amount = AppUtils.currencyToDouble(rawAmount)
        transaction.date = date
        transaction.type = selectedType
        transaction.note = note
        transaction.category = selectedCategory
        transaction.updateAt = Date()
        
        do {
            try context.save()
            onUpdate()
            dismiss()
        } catch {
            print("Lỗi khi sửa giao dịch \(error)")
        }
    }
    
    //    Xoá giao dịch
    private func deleteTransaction() {
        context.delete(transaction)
        do {
            try context.save()
            onUpdate()
            dismiss()
        } catch {
            print("Lỗi khi xoá giao dịch \(error)")
        }
    }
}
