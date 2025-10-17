import SwiftUI
import CoreData

struct TransactionDetailScreen: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var transaction: Transaction
    let onUpdate: () -> Void

    @State private var title: String = ""
    @State private var rawAmount: String = ""
    @State private var formattedAmount: String = ""
    @State private var date: Date = Date()
    @State private var type: String = "expense"
    @State private var selectedCategory: Category?
    @State private var note: String = ""

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var categories: FetchedResults<Category>

    var body: some View {
        NavigationStack {
            ZStack {
                // Nền gradient giống TransactionAddScreen
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Tiêu đề màn hình
                        Text("Chi tiết giao dịch")
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

                        // Nút lưu chỉnh sửa
                        Button(action: updateTransaction) {
                            Text("💾 Lưu chỉnh sửa")
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

                        // Nút xóa
                        Button(role: .destructive, action: deleteTransaction) {
                            Text("🗑️ Xoá giao dịch")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .padding(.top, 5)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear(perform: loadData)
        }
    }

    // MARK: - Helpers
    private func loadData() {
        title = transaction.title ?? ""
        rawAmount = String(Int(transaction.amount))
        formattedAmount = AppUtils.formatCurrencyInput(rawAmount)
        date = transaction.date ?? Date()
        type = transaction.type ?? "expense"
        selectedCategory = transaction.category
        note = transaction.note ?? ""
    }

    private var canSave: Bool {
        !title.isEmpty && AppUtils.currencyToDouble(rawAmount) > 0 && selectedCategory != nil
    }

    private func updateTransaction() {
        transaction.title = title
        transaction.amount = AppUtils.currencyToDouble(rawAmount)
        transaction.date = date
        transaction.type = type
        transaction.note = note
        transaction.category = selectedCategory
        transaction.updateAt = Date()
        do {
            try context.save()
            onUpdate()
            dismiss()
        } catch {
            print("❌ Lỗi khi sửa Transaction: \(error)")
        }
    }

    private func deleteTransaction() {
        context.delete(transaction)
        do {
            try context.save()
            onUpdate()
            dismiss()
        } catch {
            print("❌ Lỗi khi xoá Transaction: \(error)")
        }
    }
}
