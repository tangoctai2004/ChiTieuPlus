import SwiftUI
import CoreData

struct TransactionDetailScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: TransactionFormViewModel
    @StateObject private var categoryVM = CategoryViewModel()
    
    @State private var showingDeleteConfirmation = false
    
    init(viewModel: TransactionFormViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 12) {
                    TransactionFormFields(viewModel: viewModel)
                        .formSectionStyle()
                    CategorySelectionGrid(viewModel: viewModel, categoryVM: categoryVM)
                        .formSectionStyle()
                }
                .padding()
            }
            
            HStack(spacing: 15) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Text("Xoá")
                }
                .buttonStyle(DestructiveActionButtonStyle())
                
                Button(action: updateTransaction) {
                    Text("Lưu chỉnh sửa")
                }
                .buttonStyle(PrimaryActionButtonStyle(isEnabled: viewModel.canSave))
                .disabled(!viewModel.canSave)
            }
            .bottomActionBar()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onTapGesture { hideKeyboard() }
        .onAppear {
            viewModel.reinitializeFromTransaction()
            categoryVM.fetchAllCategories()
        }
        .alert("Xác nhận xoá", isPresented: $showingDeleteConfirmation) {
            Button("Chắc chắn xoá", role: .destructive) { delete() }
            Button("Không", role: .cancel) {}
        } message: {
            Text("Bạn có chắc chắn muốn xoá giao dịch này không?")
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary).fontWeight(.medium)
                }
            }
            ToolbarItemGroup(placement: .principal) {
                Picker("", selection: $viewModel.type) {
                    Text("Tiền chi").tag("expense")
                    Text("Tiền thu").tag("income")
                }
                .pickerStyle(.segmented).frame(width: 180)
            }
        }
        .toolbarBackground(Color(.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .addSwipeBackGesture()
    }

    private func updateTransaction() {
        viewModel.save()
        dismiss()
    }

    private func delete() {
        viewModel.delete()
        dismiss()
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
