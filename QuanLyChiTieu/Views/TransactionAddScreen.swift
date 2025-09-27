//
//  TransactionAddScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 26/9/25.
//

import SwiftUI
import CoreData

struct TransactionAddScreen: View {
    //    Truy cập context lưu dữ liệu
    @Environment(\.managedObjectContext) private var context
    //    Đóng cửa sổ (quay lại màn trước)
    @Environment(\.dismiss) private var dismiss
    //    Thông báo lưu thành công
    @State private var showSuccessToast: Bool = false
    
    //    Trạng thái lưu dữ liệu
    @State private var title: String = "" // Tiêu đề
    @State private var rawAmount: String = "" // Tiền chưa định dạng
    @State private var formattedAmount: String = "" // Tiền định dạng để hiển thị
    @State private var date: Date = Date() // Ngày giao dịch
    @State private var type: String = "expense" // Mặc định loại giao dịch là chi tiêu (expense)
    @State private var selectedCategory: Category? // Danh mục
    @State private var note: String = "" // Ghi chú
    
    //    Fetch danh mục từ Core Data
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var categories: FetchedResults<Category>
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Nền màu giống HomeScreen
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
                        
                        // Chọn ngày giao dịch
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
                        
                        // Chọn loại thu / chi
                        PickerWithStyle(
                            title: "Loại giao dịch",
                            systemImage: "arrow.left.arrow.right.circle",
                            selection: $type,
                            options: AppUtils.transactionTypes.map { ($0, AppUtils.displayType($0)) }
                        )
                        
                        // Chọn danh mục
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
                        
                        // Nút lưu
                        Button(action: saveTransaction) {
                            Text("💾 Lưu giao dịch")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.red, .orange], // đồng bộ màu với HomeScreen
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                        }
                        .disabled(!canSave) // Lưu khi đủ điều kiện
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Thêm giao dịch")
            .navigationBarTitleDisplayMode(.inline)
            .alert("✅ Đã thêm giao dịch", isPresented: $showSuccessToast) {
                Button("Đồng ý", role: .cancel) {}
            }
        }
    }
    
    //    Điều kiện lưu thông tin
    private var canSave: Bool {
        !title.isEmpty && AppUtils.currencyToDouble(rawAmount) > 0 && selectedCategory != nil
    }
    
    //    Lưu giao dịch vào CoreData
    private func saveTransaction() {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        newTransaction.title = title
        newTransaction.amount = AppUtils.currencyToDouble(rawAmount)
        newTransaction.date = date
        newTransaction.type = (type == "income" || type == "expense") ? type : "expense"
        newTransaction.note = note
        newTransaction.category = selectedCategory
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        do {
            try context.save()
            resetForm()
            showSuccessToast = true
        } catch {
            print("Lỗi khi lưu giao dịch chi tiêu: \(error)")
        }
    }
    
    //    Xóa dữ liệu trong form khi đã nhập xong
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
