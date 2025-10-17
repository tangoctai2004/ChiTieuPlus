import SwiftUI
import CoreData
import AVFoundation

// MARK: - Main View
struct TransactionAddScreen: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject var draft: TransactionDraft

    @State private var showSuccessToast = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var categories: FetchedResults<Category>

    private var canSave: Bool {
        AppUtils.currencyToDouble(draft.rawAmount) > 0 && draft.selectedCategory != nil
    }

    var body: some View {
        // Bọc trong NavigationStack để NavigationLink hoạt động
        NavigationStack {
            ZStack {
                // --- Giao diện chính ---
                VStack(spacing: 0) {
                    CustomAddHeaderView(selectedType: $draft.type)

                    ScrollView {
                        VStack(spacing: 12) {
                            // --- Thẻ nhập thông tin ---
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Tiêu đề")
                                        .font(.subheadline)
                                    TextField("Nhập tiêu đề", text: $draft.transactionTitle)
                                        .multilineTextAlignment(.trailing)
                                        .font(.subheadline)
                                }
                                .padding()
                                Divider().padding(.leading)
                                
                                HStack {
                                    Text("Ngày")
                                        .font(.subheadline)
                                    Spacer()
                                    DatePicker("", selection: $draft.date, displayedComponents: .date)
                                        .labelsHidden()
                                        .environment(\.locale, Locale(identifier: "vi_VN"))
                                }
                                .padding()
                                Divider().padding(.leading)
                                
                                HStack {
                                    Text("Ghi chú")
                                        .font(.subheadline)
                                    TextField("Chưa nhập vào", text: $draft.note)
                                        .multilineTextAlignment(.trailing)
                                        .font(.subheadline)
                                }
                                .padding()
                                Divider().padding(.leading)
                                
                                HStack {
                                    Text(draft.type == "expense" ? "Tiền chi" : "Tiền thu")
                                        .font(.subheadline)
                                    Spacer()
                                    TextField("0", text: $draft.formattedAmount)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .font(.subheadline)
                                        .onChange(of: draft.formattedAmount) { newValue in
                                            let digits = newValue.filter { "0123456789".contains($0) }
                                            draft.rawAmount = digits
                                            draft.formattedAmount = AppUtils.formatCurrencyInput(digits)
                                        }
                                    Text("đ")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            
                            // --- Thẻ chọn danh mục ---
                            VStack(alignment: .leading) {
                                Text("Danh mục")
                                    .font(.subheadline)
                                    .padding([.top, .horizontal])

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                                    ForEach(categories.filter { $0.type == self.draft.type }) { category in
                                        CategoryGridButton(
                                            category: category,
                                            isSelected: self.draft.selectedCategory == category
                                        ) {
                                            self.draft.selectedCategory = category
                                        }
                                    }
                                    
                                    // SỬA ĐỔI QUAN TRỌNG:
                                    // Cập nhật destination để dẫn đến CategoryListScreen
                                    NavigationLink(destination: CategoryListScreen(context: context, isPushed: true)) {
                                        EditCategoryButton()
                                    }
                                }
                                .padding([.horizontal, .bottom])
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                    
                    // --- Nút Lưu ---
                    Button(action: saveTransaction) {
                        Text(draft.type == "expense" ? "Nhập khoản chi" : "Nhập khoản thu")
                    }
                    .buttonStyle(AnimatedButtonStyle(isEnabled: canSave))
                    .disabled(!canSave)
                    .padding()
                    .background(Color.white.shadow(radius: 2, x: 0, y: -2))
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarHidden(true)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onTapGesture {
                    hideKeyboard()
                }
                
                // --- Lớp hiển thị thông báo thành công ---
                if showSuccessToast {
                    SuccessToastView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showSuccessToast = false
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func saveTransaction() {
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        newTransaction.title = draft.transactionTitle.isEmpty ? (draft.selectedCategory?.name ?? "Giao dịch") : draft.transactionTitle
        newTransaction.note = draft.note
        newTransaction.amount = AppUtils.currencyToDouble(draft.rawAmount)
        newTransaction.date = draft.date
        newTransaction.type = draft.type
        newTransaction.category = draft.selectedCategory
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        do {
            try context.save()
            draft.reset()
            withAnimation {
                showSuccessToast = true
            }
        } catch {
            print("❌ Lỗi khi lưu Transaction: \(error)")
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Success Toast View
struct SuccessToastView: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)
                .symbolEffect(.bounce.down.byLayer, value: true)

            Text("Thêm giao dịch thành công")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(30)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .onAppear(perform: playSound)
    }
    
    func playSound() {
        AudioServicesPlaySystemSound(1306)
    }
}

// MARK: - Animated Button Style
struct AnimatedButtonStyle: ButtonStyle {
    var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                ZStack(alignment: .leading) {
                    Color.gray
                    Color.green
                        .frame(width: isEnabled ? nil : 0, alignment: .leading)
                }
                .animation(.easeInOut(duration: 0.5), value: isEnabled)
            )
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Các View phụ khác
struct CustomAddHeaderView: View {
    @Binding var selectedType: String

    var body: some View {
        HStack {
            Spacer()
            
            Picker("", selection: $selectedType.animation()) {
                Text("Tiền chi").tag("expense")
                Text("Tiền thu").tag("income")
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .frame(height: 44)
        .background(Color.white)
    }
}

struct CategoryGridButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.iconName ?? "questionmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(IconProvider.color(for: category.iconName))
                
                Text(category.name ?? "N/A")
                    .font(.caption2)
                    .foregroundColor(isSelected ? IconProvider.color(for: category.iconName) : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 70)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? IconProvider.color(for: category.iconName) : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct EditCategoryButton: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Chỉnh sửa")
                .font(.caption2)
                .foregroundColor(.primary)
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 80, height: 70)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
