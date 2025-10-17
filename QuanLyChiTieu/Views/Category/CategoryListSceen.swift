import SwiftUI
import CoreData

// MARK: - Main View
struct CategoryListScreen: View {
    @StateObject private var viewModel: CategoryViewModel
    
    // State để điều khiển bộ lọc Chi tiêu/Thu nhập
    @State private var selectedType = "expense"
    // State để bật/tắt chế độ chỉnh sửa
    @State private var isEditing = false
    
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: CategoryViewModel(context: context))
    }
    
    // Lấy danh sách categories đã được lọc theo type
    private var filteredCategories: [Category] {
        viewModel.categories.filter { $0.type == selectedType }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Custom Header
                CustomHeaderView(
                    selectedType: $selectedType,
                    isEditing: $isEditing
                )
                
                ScrollView {
                    VStack(spacing: 12) {
                        // MARK: - Add Category Button
                        NavigationLink(destination: CategoryAddScreen(viewModel: viewModel)) {
                            HStack {
                                Text("Thêm danh mục")
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                        
                        // MARK: - Categories List
                        List {
                            ForEach(filteredCategories) { category in
                                // NavigationLink chỉ hoạt động khi không ở chế độ chỉnh sửa
                                NavigationLink(destination: CategoryEditScreen(viewModel: viewModel, category: category)) {
                                    EditableCategoryRow(category: category)
                                }
                                .disabled(isEditing)
                            }
                            .onDelete(perform: deleteCategory)
                            .onMove(perform: moveCategory) // Bật chức năng di chuyển
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .frame(height: CGFloat(filteredCategories.count) * 70) // Điều chỉnh chiều cao động
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            .animation(.default, value: isEditing)
            .animation(.default, value: filteredCategories)
        }
    }
    
    // MARK: - Helper Functions
    private func deleteCategory(at offsets: IndexSet) {
        offsets.forEach { index in
            let categoryToDelete = filteredCategories[index]
            viewModel.deleteCategory(categoryToDelete)
        }
    }
    
    private func moveCategory(from source: IndexSet, to destination: Int) {
        // Chức năng này yêu cầu logic sắp xếp trong ViewModel, tạm thời để trống
        // viewModel.moveCategory(from: source, to: destination, type: selectedType)
        print("Moved item. Logic to save new order needs implementation.")
    }
}

// MARK: - Custom Header View
struct CustomHeaderView: View {
    @Binding var selectedType: String
    @Binding var isEditing: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.medium))
                }
                .frame(width: 44)
                
                Spacer()
                
                Picker("", selection: $selectedType) {
                    Text("Chi tiêu").tag("expense")
                    Text("Thu nhập").tag("income")
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                Button(isEditing ? "Hoàn thành" : "Chỉnh sửa") {
                    isEditing.toggle()
                }
                .frame(width: 80)
            }
            .padding(.horizontal)
            .foregroundColor(.primary)
        }
        .frame(height: 90)
        .background(Color.white.shadow(radius: 1))
    }
}

// MARK: - Editable Category Row
struct EditableCategoryRow: View {
    @ObservedObject var category: Category
    @Environment(\.editMode) private var editMode
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: category.iconName ?? "questionmark.circle")
                .font(.title2)
                .foregroundColor(Color(uiColor: .label))
                .frame(width: 30)
            
            Text(category.name ?? "Không có tên")
                .font(.system(.headline))
            
            Spacer()
            
            if editMode?.wrappedValue == .inactive {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}
