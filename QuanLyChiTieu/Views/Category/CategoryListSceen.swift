import SwiftUI
import CoreData

// MARK: - Main View
struct CategoryListScreen: View {
    // SỬA ĐỔI: ViewModel được khởi tạo trực tiếp, không cần context
    @StateObject private var viewModel = CategoryViewModel()
    
    // Các state điều khiển UI được giữ nguyên
    @State private var selectedType = "expense"
    @State private var isEditing = false
    @State private var showingDeleteConfirmation = false
    @State private var showSuccessAlert = false
    @State private var categoryToDelete: Category? = nil
    
    // Bỏ init cũ, không cần `isPushed` nữa vì NavigationStack sẽ tự xử lý
    
    private var filteredCategories: [Category] {
        // SỬA ĐỔI: Lấy dữ liệu từ viewModel
        viewModel.categories.filter { $0.type == selectedType }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // CustomHeaderView được giữ nguyên 100%
                CustomHeaderView(
                    selectedType: $selectedType,
                    isEditing: $isEditing,
                    // Giả định isPushed không còn cần thiết
                    // Nếu bạn cần logic back đặc biệt, có thể thêm lại
                    isPushed: false
                )
                
                ScrollView {
                    VStack(spacing: 8) {
                        // NavigationLink để thêm Category (Giữ nguyên)
                        NavigationLink(destination: CategoryAddScreen(viewModel: viewModel)) {
                            HStack(spacing: 12) {
                                Spacer().frame(width: isEditing ? 57 : 24)
                                Text("Thêm danh mục")
                                    .font(.callout)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        
                        // Categories List (Giữ nguyên)
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
                                        Label("Xoá", systemImage: "trash.fill")
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
            .alert("Xác nhận xoá", isPresented: $showingDeleteConfirmation) {
                Button("Chắc chắn xoá", role: .destructive) {
                    deleteConfirmed()
                }
                Button("Không", role: .cancel) { }
            } message: {
                Text("Bạn có chắc chắn muốn xoá danh mục \"\(categoryToDelete?.name ?? "")\" không? Hành động này không thể hoàn tác.")
            }
            .alert("Xoá thành công", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            }
            .onAppear {
                // SỬA ĐỔI: Yêu cầu ViewModel lấy dữ liệu
                viewModel.fetchAllCategories()
            }
        }
    }
    
    private func deleteConfirmed() {
        if let category = categoryToDelete {
            // SỬA ĐỔI: Gọi hàm xóa của ViewModel
            viewModel.deleteCategory(category)
            self.categoryToDelete = nil
            self.showSuccessAlert = true
        }
    }
}

// MARK: - Các View phụ (Giữ nguyên 100%)

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
                }
                .frame(width: 80, alignment: .leading)
            } else {
                Spacer().frame(width: 80)
            }
            
            Spacer()
            Picker("", selection: $selectedType) {
                Text("Chi tiêu").tag("expense")
                Text("Thu nhập").tag("income")
            }
            .pickerStyle(.segmented)
            .frame(width: 150)
            Spacer()
            Button(isEditing ? "Hoàn thành" : "Chỉnh sửa") {
                isEditing.toggle()
            }
            .font(.callout)
            .foregroundColor(.primary)
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(Color.white)
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
            
            Text(category.name ?? "Không có tên")
                .font(.callout)
                .foregroundColor(.primary)
            
            Spacer()
            
            if isEditing {
                Image(systemName: "line.horizontal.3")
                    .foregroundColor(.gray.opacity(0.7))
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(10)
    }
}
