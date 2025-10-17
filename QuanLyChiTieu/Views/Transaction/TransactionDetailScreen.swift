import SwiftUI
import CoreData

struct TransactionDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: TransactionEditViewModel
    
    // State để quản lý alert xác nhận xoá
    @State private var showingDeleteConfirmation = false
    
    let onUpdate: () -> Void

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var categories: FetchedResults<Category>

    init(transaction: Transaction, context: NSManagedObjectContext, onUpdate: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: TransactionEditViewModel(transaction: transaction, context: context))
        self.onUpdate = onUpdate
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Header
            CustomDetailHeader(
                selectedType: $viewModel.type,
                onBack: { dismiss() }
            )

            // MARK: - Form Inputs
            ScrollView {
                VStack(spacing: 12) {
                    // --- Thẻ nhập thông tin (cố định) ---
                    VStack(spacing: 0) {
                        HStack {
                            Text("Tiêu đề")
                                .font(.subheadline)
                            TextField("Nhập tiêu đề", text: $viewModel.transactionTitle)
                                .multilineTextAlignment(.trailing)
                                .font(.subheadline)
                        }
                        .padding()
                        Divider().padding(.leading)
                        
                        HStack {
                            Text("Ngày")
                                .font(.subheadline)
                            Spacer()
                            DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "vi_VN"))
                        }
                        .padding()
                        Divider().padding(.leading)
                        
                        HStack {
                            Text("Ghi chú")
                                .font(.subheadline)
                            TextField("Chưa nhập vào", text: $viewModel.note)
                                .multilineTextAlignment(.trailing)
                                .font(.subheadline)
                        }
                        .padding()
                        Divider().padding(.leading)
                        
                        HStack {
                            Text(viewModel.type == "expense" ? "Tiền chi" : "Tiền thu")
                                .font(.subheadline)
                            Spacer()
                            TextField("0", text: $viewModel.formattedAmount)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.subheadline)
                                .onChange(of: viewModel.formattedAmount) { newValue in
                                    let digits = newValue.filter { "0123456789".contains($0) }
                                    viewModel.rawAmount = digits
                                    viewModel.formattedAmount = AppUtils.formatCurrencyInput(digits)
                                }
                            Text("đ")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                    
                    // MARK: - Category Grid (Scrollable)
                    VStack(alignment: .leading) {
                        Text("Danh mục")
                            .font(.subheadline)
                            .padding([.top, .horizontal])

                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
                                ForEach(categories.filter { $0.type == viewModel.type }) { category in
                                    CategoryGridButton(
                                        category: category,
                                        isSelected: viewModel.selectedCategory == category
                                    ) {
                                        viewModel.selectedCategory = category
                                    }
                                }
                            }
                            .padding([.horizontal, .bottom])
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            
            // SỬA ĐỔI: Hai nút đặt cạnh nhau trong HStack
            // MARK: - Action Buttons
            HStack(spacing: 15) {
                // Nút Xoá
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text("Xoá")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(25) // Tăng độ bo tròn
                }
                
                // Nút Lưu Chỉnh Sửa
                Button(action: updateTransaction) {
                    Text("Lưu chỉnh sửa")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray) // Đổi màu thành xám
                        .cornerRadius(25) // Tăng độ bo tròn
                }
                .disabled(!viewModel.canSave)
                .opacity(viewModel.canSave ? 1.0 : 0.6)
            }
            .padding()
            .background(Color.white.shadow(radius: 2, x: 0, y: -2))
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture {
            hideKeyboard()
        }
        .alert("Xác nhận xoá", isPresented: $showingDeleteConfirmation) {
            Button("Chắc chắn xoá", role: .destructive) { delete() }
            Button("Không", role: .cancel) {}
        } message: {
            Text("Bạn có chắc chắn muốn xoá giao dịch này không?")
        }
    }

    // MARK: - Helper Functions
    private func updateTransaction() {
        viewModel.saveChanges()
        onUpdate()
        dismiss()
    }

    private func delete() {
        viewModel.deleteTransaction()
        onUpdate()
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Custom Header for Detail Screen
struct CustomDetailHeader: View {
    @Binding var selectedType: String
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.medium))
            }
            .frame(width: 44, alignment: .leading)
            
            Spacer()
            
            Picker("", selection: $selectedType) {
                Text("Tiền chi").tag("expense")
                Text("Tiền thu").tag("income")
            }
            .pickerStyle(.segmented)
            .frame(width: 180) // Thu nhỏ picker
            
            Spacer()
            
            // Placeholder để căn giữa picker
            Spacer().frame(width: 44)
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(Color.white)
    }
}
