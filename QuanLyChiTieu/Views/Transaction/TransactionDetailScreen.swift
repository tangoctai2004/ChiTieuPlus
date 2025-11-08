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
                    Text("common_delete")
                }
                .buttonStyle(DestructiveActionButtonStyle())
                
                Button(action: updateTransaction) {
                    Text("common_save_changes")
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
        // --- SỬA ĐỔI ---
        .alert(Text("alert_delete_confirmation_title"), isPresented: $showingDeleteConfirmation) {
            Button("alert_button_confirm_delete", role: .destructive) { delete() } // Bỏ Text()
            Button("alert_button_cancel", role: .cancel) {} // Bỏ Text()
        } message: {
        // --- KẾT THÚC SỬA ĐỔI ---
            Text("alert_delete_transaction_message")
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
                    Text("common_expense").tag("expense")
                    Text("common_income").tag("income")
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
