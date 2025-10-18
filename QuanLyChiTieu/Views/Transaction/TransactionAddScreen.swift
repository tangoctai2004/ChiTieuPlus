import SwiftUI
import CoreData
import AVFoundation

struct TransactionAddScreen: View {
    @EnvironmentObject var viewModel: TransactionFormViewModel
    @StateObject private var categoryVM = CategoryViewModel()
    
    @State private var showSuccessToast = false

    private var canSave: Bool {
        viewModel.canSave
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    CustomAddHeaderView(selectedType: $viewModel.type)

                    ScrollView {
                        VStack(spacing: 12) {
                            TransactionFormFields(viewModel: viewModel)
                            CategorySelectionGrid(viewModel: viewModel, categoryVM: categoryVM)
                        }
                        .padding()
                    }
                    
                    Button(action: saveTransaction) {
                        Text(viewModel.type == "expense" ? "Nhập khoản chi" : "Nhập khoản thu")
                    }
                    .buttonStyle(AnimatedButtonStyle(isEnabled: canSave))
                    .disabled(!canSave)
                    .padding()
                    .background(
                        Color(.systemGroupedBackground)
                            .shadow(
                                color: Color.primary.opacity(0.1),
                                radius: 2,
                                x: 0,
                                y: -2
                            )
                    )
                    .padding(.bottom, 35)
                }
                .background(Color(.systemGroupedBackground))
                .navigationBarHidden(true)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onTapGesture { hideKeyboard() }
                .onAppear {
                    categoryVM.fetchAllCategories()
                }
                
                if showSuccessToast {
                    SuccessToastView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation { showSuccessToast = false }
                            }
                        }
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
    
    private func saveTransaction() {
        viewModel.save()
        viewModel.reset()
        withAnimation { showSuccessToast = true }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Form Fields
struct TransactionFormFields: View {
    @ObservedObject var viewModel: TransactionFormViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tiêu đề").font(.subheadline)
                TextField("Nhập tiêu đề", text: $viewModel.transactionTitle)
                    .multilineTextAlignment(.trailing).font(.subheadline)
            }.padding()
            Divider().padding(.leading)
            
            HStack {
                Text("Ngày").font(.subheadline)
                Spacer()
                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                    .labelsHidden().environment(\.locale, Locale(identifier: "vi_VN"))
            }.padding()
            Divider().padding(.leading)
            
            HStack {
                Text("Ghi chú").font(.subheadline)
                TextField("Chưa nhập vào", text: $viewModel.note)
                    .multilineTextAlignment(.trailing).font(.subheadline)
            }.padding()
            Divider().padding(.leading)
            
            HStack {
                Text(viewModel.type == "expense" ? "Tiền chi" : "Tiền thu").font(.subheadline)
                Spacer()
                TextField("0", text: $viewModel.formattedAmount)
                    .keyboardType(.numberPad).multilineTextAlignment(.trailing).font(.subheadline)
                    .onChange(of: viewModel.formattedAmount) { newValue in
                        let digits = newValue.filter { "0123456789".contains($0) }
                        viewModel.rawAmount = digits
                        viewModel.formattedAmount = AppUtils.formatCurrencyInput(digits)
                    }
                Text("đ").foregroundColor(.secondary)
            }.padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}


// Các View phụ khác
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
        // SỬA ĐỔI: Dùng .systemBackground thay vì .white
        .background(Color(.systemBackground))
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
                    .foregroundColor(isSelected ? IconProvider.color(for: category.iconName) : .secondary) // .secondary đã hỗ trợ
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 70)
            .background(Color(.systemGray6)) // Giữ nguyên
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
        .background(Color(.systemGray6)) // Giữ nguyên
        .cornerRadius(10)
    }
}

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
        .background(.ultraThinMaterial) // Giữ nguyên, đã hỗ trợ
        .cornerRadius(20)
        // SỬA ĐỔI: Dùng .primary.opacity(0.15) cho shadow
        .shadow(color: Color.primary.opacity(0.15), radius: 10, y: 5)
        .onAppear(perform: playSound)
    }
    
    func playSound() {
        AudioServicesPlaySystemSound(1306)
    }
}

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

// MARK: - Category Grid
struct CategorySelectionGrid: View {
    @ObservedObject var viewModel: TransactionFormViewModel
    @ObservedObject var categoryVM: CategoryViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Danh mục")
                .font(.subheadline)
                .padding([.top, .horizontal])

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                ForEach(categoryVM.categories.filter { $0.type == viewModel.type }) { category in
                    CategoryGridButton(
                        category: category,
                        isSelected: viewModel.selectedCategoryID == category.objectID
                    ) {
                        viewModel.selectedCategory = category
                        viewModel.selectedCategoryID = category.objectID
                    }
                }
                
                NavigationLink(destination: CategoryListScreen(isPresentingModal: true)) {
                    EditCategoryButton()
                }
            }
            .padding([.horizontal, .bottom])
        }
        .background(Color(.systemBackground)) // Giữ nguyên
        .cornerRadius(10)
    }
}
