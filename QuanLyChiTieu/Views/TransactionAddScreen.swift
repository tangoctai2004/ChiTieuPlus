//
//  TransactionAddScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 26/9/25.
//

import SwiftUI
import CoreData

struct TransactionAddScreen: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessToast: Bool = false
    
    // Trạng thái lưu dữ liệu
    @State private var title: String = ""
    @State private var rawAmount: String = ""
    @State private var formattedAmount: String = ""
    @State private var date: Date = Date()
    @State private var type: String = "expense"
    @State private var selectedCategory: Category?
    @State private var note: String = ""
    
    // Fetch danh mục từ CoreData
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Nền gradient đồng bộ
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // ✅ Tiêu đề app
                        Text("Thêm giao dịch")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .gradientText(colors: [.yellow, .orange, .green])
                            .padding(.top, 10)
                        
                        // Ô nhập tiêu đề
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
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        
                        // Loại giao dịch (Thu / Chi)
                        PickerWithStyle(
                            title: "Loại giao dịch",
                            systemImage: "arrow.left.arrow.right.circle",
                            selection: $type,
                            options: AppUtils.transactionTypes.map { ($0, AppUtils.displayType($0)) }
                        )
                        
                        // Danh mục
                        PickerWithStyleCategory(
                            title: "Danh mục",
                            systemImage: "folder",
                            selection: $selectedCategory,
                            categories: categories.filter { $0.type == type }
                        )
                        
                        // Ghi chú
                        TextFieldWithIcon(
                            systemName: "note.text",
                            placeholder: "Ghi chú",
                            text: $note
                        )
                        
                        // ✅ Nút lưu gradient
                        Button(action: saveTransaction) {
                            Text("💾 Lưu giao dịch")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .disabled(!canSave)
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .alert("✅ Đã thêm giao dịch", isPresented: $showSuccessToast) {
                Button("Đồng ý", role: .cancel) { dismiss() }
            }
            .navigationBarHidden(true) // Ẩn header mặc định, dùng tiêu đề custom
        }
    }
    
    // Điều kiện lưu
    private var canSave: Bool {
        !title.isEmpty && AppUtils.currencyToDouble(rawAmount) > 0 && selectedCategory != nil
    }
    
    // Lưu vào CoreData
    private func saveTransaction() {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        newTransaction.title = title
        newTransaction.amount = AppUtils.currencyToDouble(rawAmount)
        newTransaction.date = date
        newTransaction.type = type
        newTransaction.note = note
        newTransaction.category = selectedCategory
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        do {
            try context.save()
            resetForm()
            showSuccessToast = true
        } catch {
            print("❌ Lỗi khi lưu Transaction: \(error)")
        }
    }
    
    private func resetForm() {
        title = ""
        rawAmount = ""
        formattedAmount = ""
        date = Date()
        type = "expense"
        selectedCategory = nil
        note = ""
    }
}

struct TextFieldWithIcon: View {
    let systemName: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: systemName)
                .foregroundColor(.secondary) // đổi từ xanh -> secondary cho nhẹ nhàng
            TextField(placeholder, text: $text)
                .autocorrectionDisabled()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

//    Picker chọn loại giao dịch với style segment
struct PickerWithStyle: View {
    let title: String
    let systemImage: String
    @Binding var selection: String
    let options: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .foregroundColor(.primary)
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.0) { value, label in
                    Text(label).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .tint(.orange) // đồng bộ với HomeScreen
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

//    Picker chọn danh mục từ Core Data
struct PickerWithStyleCategory: View {
    let title: String
    let systemImage: String
    @Binding var selection: Category?
    let categories: [Category]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .foregroundColor(.primary)
            
            Picker(title, selection: $selection) {
                Text("Chọn danh mục").tag(Category?.none)
                ForEach(categories, id: \.self) { cate in
                    Text(cate.name ?? "").tag(Category?.some(cate))
                }
            }
            .pickerStyle(.menu)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}
