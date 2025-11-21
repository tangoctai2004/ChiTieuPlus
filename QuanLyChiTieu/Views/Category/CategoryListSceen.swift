import SwiftUI
import CoreData

// MARK: - Main View
struct CategoryListScreen: View {
    var isPresentingModal: Bool = false
    
    @StateObject private var viewModel = CategoryViewModel()
    @StateObject private var navigationCoordinator = NavigationCoordinator.shared
    
    @State private var selectedType = "expense"
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var showSuccessAlert = false
    @State private var categoryToDelete: Category? = nil
    
    private var filteredCategories: [Category] {
        viewModel.categories.filter { $0.type == selectedType }
    }
    
    var body: some View {
        NavigationStack(path: isPresentingModal ? Binding.constant(NavigationPath()) : navigationCoordinator.path(for: 2)) {
            VStack(spacing: 0) {
                CustomHeaderView(
                    selectedType: $selectedType,
                    isEditing: $isEditing,
                    isPushed: isPresentingModal
                )
                
                ScrollView {
                    VStack(spacing: 8) {
                        NavigationLink(destination: CategoryAddScreen(viewModel: viewModel)) {
                            HStack(spacing: 12) {
                                Spacer().frame(width: isEditing ? 57 : 24)
                                Text("category_list_add")
                                    .font(.callout)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                        
                        ForEach(filteredCategories) { category in
                            Group {
                                if isEditing {
                                    EditableCategoryRow(
                                        category: category,
                                        isEditing: $isEditing,
                                        onDelete: {
                                            self.categoryToDelete = category
                                            self.showingDeleteConfirmation = true
                                        }
                                    )
                                } else {
                                    NavigationLink(destination: CategoryEditScreen(viewModel: viewModel, category: category)) {
                                        EditableCategoryRow(category: category, isEditing: $isEditing)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                if isEditing {
                                    Button(role: .destructive) {
                                        self.categoryToDelete = category
                                        self.showingDeleteConfirmation = true
                                    } label: {
                                        Label("common_delete", systemImage: "trash.fill")
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .animation(.default, value: isEditing)
            .animation(.default, value: filteredCategories)
            // --- SỬA ĐỔI ---
            .alert(Text("alert_delete_confirmation_title"), isPresented: $showingDeleteConfirmation) {
                Button("alert_button_confirm_delete", role: .destructive) { // Bỏ Text()
                    deleteConfirmed()
                }
                Button("alert_button_cancel", role: .cancel) { } // Bỏ Text()
            } message: {
                Text(String.localizedStringWithFormat(NSLocalizedString("alert_delete_category_message", comment: ""), categoryToDelete?.name ?? ""))
            }
            .alert(Text("alert_delete_success_title"), isPresented: $showSuccessAlert) {
                Button("alert_button_ok", role: .cancel) { } // Bỏ Text()
            }
            // --- KẾT THÚC SỬA ĐỔI ---
            .onAppear {
                viewModel.fetchAllCategories()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PopToRoot"))) { notification in
                if let tab = notification.userInfo?["tab"] as? Int, tab == 2, !isPresentingModal {
                    navigationCoordinator.popToRoot(for: 2)
                }
            }
        }
    }
    
    private func deleteConfirmed() {
        if let category = categoryToDelete {
            viewModel.deleteCategory(category)
            self.categoryToDelete = nil
            self.showSuccessAlert = true
        }
    }
}

// MARK: - Các View phụ
struct CustomHeaderView: View {
    @Binding var selectedType: String
    @Binding var isEditing: Bool
    
    var isPushed: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            if isPushed {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.primary)
                }
                .frame(width: 80, alignment: .leading)
            } else {
                Spacer().frame(width: 80)
            }
            
            Spacer()
            Picker("", selection: $selectedType) {
                Text("common_expense").tag("expense")
                Text("common_income").tag("income")
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            Spacer()
            // --- SỬA ĐỔI ---
            Button(action: { // Đổi cú pháp Button
                isEditing.toggle()
            }) {
                isEditing ? Text("common_done") : Text("common_edit")
            }
            // --- KẾT THÚC SỬA ĐỔI ---
            .font(.callout)
            .foregroundColor(.primary)
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(Color(.systemBackground))
    }
}

struct EditableCategoryRow: View {
    @ObservedObject var category: Category
    @Binding var isEditing: Bool
    var onDelete: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                Button(action: {
                    onDelete?()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            Image(systemName: category.iconName ?? "questionmark.circle")
                .font(.title3)
                .foregroundColor(IconProvider.color(for: category.iconName))
                .frame(width: 24)
            
            Text(LocalizedStringKey(category.name ?? "common_no_name"))
                .font(.callout)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isEditing {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.secondary.opacity(0.7))
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}
