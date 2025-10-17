import SwiftUI
import CoreData

// MARK: - Main View
struct TransactionAddScreen: View {
    @Environment(\.managedObjectContext) private var context
    
    // SỬA ĐỔI: Thêm state cho Tiêu đề và đổi tên `title` thành `note` cho rõ ràng
    @State private var transactionTitle: String = ""
    @State private var note: String = ""
    @State private var rawAmount: String = ""
    @State private var formattedAmount: String = ""
    @State private var date: Date = Date()
    @State private var type: String = "expense"
    @State private var selectedCategory: Category?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var categories: FetchedResults<Category>
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header (Segmented Control)
            Picker("Loại giao dịch", selection: $type.animation()) {
                Text("Tiền chi").tag("expense")
                Text("Tiền thu").tag("income")
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.white)

            // MARK: - Form Inputs
            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 0) {
                        // SỬA ĐỔI: Thêm dòng Tiêu đề tại đây
                        HStack {
                            Text("Tiêu đề")
                                .font(.headline)
                            TextField("Nhập tiêu đề", text: $transactionTitle)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding()

                        Divider().padding(.leading)
                        
                        // Ngày
                        HStack {
                            Text("Ngày")
                                .font(.headline)
                            Spacer()
                            DatePicker(
                                "",
                                selection: $date,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "vi_VN"))
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Ghi chú
                        HStack {
                            Text("Ghi chú")
                                .font(.headline)
                            TextField("Chưa nhập vào", text: $note)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding()
                        
                        Divider().padding(.leading)
                        
                        // Tiền chi / Tiền thu
                        HStack {
                            Text(type == "expense" ? "Tiền chi" : "Tiền thu")
                                .font(.headline)
                            Spacer()
                            TextField("0", text: $formattedAmount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: formattedAmount) { newValue in
                                    let digits = newValue.filter { "0123456789".contains($0) }
                                    rawAmount = digits
                                    formattedAmount = digits
                                }
                            Text("đ")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    
                    // MARK: - Category Grid
                    VStack(alignment: .leading) {
                        Text("Danh mục")
                            .font(.headline)
                            .padding(.leading)
                            .padding(.top)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 15) {
                            ForEach(categories.filter { $0.type == self.type }) { category in
                                CategoryGridButton(
                                    category: category,
                                    isSelected: self.selectedCategory == category
                                ) {
                                    self.selectedCategory = category
                                }
                            }
                            
                            NavigationLink(destination: Text("Màn hình chỉnh sửa danh mục")) {
                                EditCategoryButton()
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        
                    }
                    .background(Color.white)
                    .cornerRadius(10)

                }
                .padding()
            }
            
            // MARK: - Save Button
            Button(action: saveTransaction) {
                Text(type == "expense" ? "Nhập khoản chi" : "Nhập khoản thu")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.9))
                    .cornerRadius(12)
            }
            .disabled(!canSave)
            .padding([.horizontal, .bottom])
            .background(Color.white.shadow(radius: 2, x: 0, y: -2))

        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Helper Functions
    
    private var canSave: Bool {
        // Tiêu đề và Ghi chú có thể trống, nhưng tiền và danh mục thì không
        !rawAmount.isEmpty && (Double(rawAmount) ?? 0) > 0 && selectedCategory != nil
    }
    
    private func saveTransaction() {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        // SỬA ĐỔI: Lưu cả tiêu đề và ghi chú
        newTransaction.title = transactionTitle.isEmpty ? (selectedCategory?.name ?? "Giao dịch") : transactionTitle
        newTransaction.note = note
        newTransaction.amount = Double(rawAmount) ?? 0
        newTransaction.date = date
        newTransaction.type = type
        newTransaction.category = selectedCategory
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        do {
            try context.save()
            resetForm()
        } catch {
            print("❌ Lỗi khi lưu Transaction: \(error)")
        }
    }
    
    private func resetForm() {
        // SỬA ĐỔI: Reset cả tiêu đề và ghi chú
        transactionTitle = ""
        note = ""
        rawAmount = ""
        formattedAmount = ""
        date = Date()
        selectedCategory = nil
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


// MARK: - Subviews for Category Grid
// (Không thay đổi)
struct CategoryGridButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.iconName ?? "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .orange : .primary)
                
                Text(category.name ?? "N/A")
                    .font(.caption)
                    .foregroundColor(isSelected ? .orange : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct EditCategoryButton: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Chỉnh sửa")
                .font(.caption)
                .foregroundColor(.primary)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 80)
        .background(Color(.systemGray6))
        .cornerRadius(10)
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
