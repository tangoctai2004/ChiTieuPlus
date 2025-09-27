//
//  CategoryManageScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 26/9/25.
//

import SwiftUI
import CoreData

struct CategoryManageScreen: View {
    @Environment(\.managedObjectContext) private var context
    @State private var selectedType: String = "expense" // Loại danh mục (thu / chi)
    @State private var name: String = "" // Tên danh mục
    @State private var editingCategory: Category? = nil // Danh mục đang chỉnh sửa
    
    // Fetch tất cả Category từ CoreData
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Category.name, ascending: true)],
        animation: .default
    ) private var allCategories: FetchedResults<Category>
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Chọn loại danh mục (Thu / Chi)
                        PickerWithStyle(
                            title: "Loại danh mục",
                            systemImage: "arrow.left.arrow.right.circle",
                            selection: $selectedType,
                            options: AppUtils.transactionTypes.map { ($0, AppUtils.displayType($0)) }
                        )
                        
                        // Ô nhập tên danh mục
                        TextFieldWithIcon(
                            systemName: "folder.badge.plus",
                            placeholder: "Tên danh mục",
                            text: $name
                        )
                        
                        // Nút thêm hoặc cập nhật danh mục
                        Button(action: {
                            if let category = editingCategory {
                                updateCategory(category)
                            } else {
                                addCategory()
                            }
                        }) {
                            Text(editingCategory == nil ? "➕ Thêm danh mục" : "✏️ Cập nhật danh mục")
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
                                .cornerRadius(14)
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) // Chỉ bật khi có tên danh mục
                        
                        // Danh sách danh mục
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Danh sách danh mục", systemImage: "list.bullet")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            ForEach(filteredCategories, id: \.self) { category in
                                HStack {
                                    Text(category.name ?? "")
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Button("Sửa") {
                                        name = category.name ?? ""
                                        editingCategory = category
                                        selectedType = category.type ?? "expense"
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(role: .destructive) {
                                        deleteCategory(category)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemBackground)))
                                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                            }
                        }
                        .padding(.top, 10)
                        
                    }
                    .padding()
                }
            }
            .navigationTitle("Danh mục")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Lọc danh mục theo loại đang chọn
    private var filteredCategories: [Category] {
        allCategories.filter { $0.type == selectedType }
    }
    
    // Thêm danh mục
    private func addCategory() {
        let newCategory = Category(context: context)
        newCategory.id = UUID()
        newCategory.name = name.trimmingCharacters(in: .whitespaces)
        newCategory.type = selectedType
        newCategory.createAt = Date()
        newCategory.updateAt = Date()
        
        saveContext()
        resetForm()
    }
    
    // Cập nhật danh mục
    private func updateCategory(_ category: Category) {
        category.name = name.trimmingCharacters(in: .whitespaces)
        category.type = selectedType
        category.updateAt = Date()
        
        saveContext()
        resetForm()
    }
    
    // Xoá danh mục
    private func deleteCategory(_ category: Category) {
        context.delete(category)
        
        saveContext()
        resetForm()
    }
    
    // Lưu vào CoreData
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ Lỗi khi lưu Category: \(error)")
        }
    }
    
    // Reset form sau khi xử lý
    private func resetForm() {
        name = ""
        editingCategory = nil
    }
}
