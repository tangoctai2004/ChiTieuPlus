import SwiftUI
import CoreData

struct TransactionDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    // Chỉ cần 1 viewModel của riêng nó
    @StateObject var viewModel: TransactionFormViewModel
    @StateObject private var categoryVM = CategoryViewModel()
    
    @State private var showingDeleteConfirmation = false
    
    // Chỉ cần init đơn giản
    init(viewModel: TransactionFormViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            CustomDetailHeader(selectedType: $viewModel.type, onBack: { dismiss() })

            ScrollView {
                VStack(spacing: 12) {
                    TransactionFormFields(viewModel: viewModel)
                    CategorySelectionGrid(viewModel: viewModel, categoryVM: categoryVM)
                }
                .padding()
            }
            
            HStack(spacing: 15) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text("Xoá")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .cornerRadius(25)
                }
                
                Button(action: updateTransaction) {
                    Text("Lưu chỉnh sửa")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gray)
                        .cornerRadius(25)
                }
                .disabled(!viewModel.canSave)
                .opacity(viewModel.canSave ? 1.0 : 0.6)
            }
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
        .alert("Xác nhận xoá", isPresented: $showingDeleteConfirmation) {
            Button("Chắc chắn xoá", role: .destructive) { delete() }
            Button("Không", role: .cancel) {}
        } message: {
            Text("Bạn có chắc chắn muốn xoá giao dịch này không?")
        }
    }

    private func updateTransaction() {
        // Chỉ cần save
        viewModel.save()
        dismiss()
    }

    private func delete() {
        // Chỉ cần delete
        viewModel.delete()
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Custom Header
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
            .frame(width: 180)
            
            Spacer()
            
            Spacer().frame(width: 44)
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(Color(.systemBackground))
    }
}
