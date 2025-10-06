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
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        Text("Quản lý danh mục")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .gradientText(colors: [.yellow, .orange, .green])
                            .padding(.top, 10)
                        
                        PickerWithStyle(
                            title: "Loại danh mục",
                            systemImage: "arrow.left.arrow.right.circle",
                            selection: $selectedType,
                            options: AppUtils.transactionTypes.map { ($0, AppUtils.displayType($0)) }
                        )
                        
                        TextFieldWithIcon(
                            systemName: "folder.badge.plus",
                            placeholder: "Tên danh mục",
                            text: $name
                        )
                        
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
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                        }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Danh sách danh mục", systemImage: "list.bullet")
                                .font(.headline)
                                .padding(.bottom, 4)
                                .foregroundColor(.blue)
                            
                            ForEach(filteredCategories, id: \.self) { category in
                                HStack {
                                    Text(category.name ?? "")
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        name = category.name ?? ""
                                        editingCategory = category
                                        selectedType = category.type ?? "expense"
                                    } label: {
                                        Text("Sửa")
                                            .font(.subheadline)
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(role: .destructive) {
                                        deleteCategory(category)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color(.systemGray6))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                )
                            }
                        }
                        .padding(.top, 10)
                        
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Lọc danh mục theo loại
    private var filteredCategories: [Category] {
        allCategories.filter { $0.type == selectedType }
    }
    
    // MARK: - Thêm danh mục
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
    
    // MARK: - Cập nhật danh mục
    private func updateCategory(_ category: Category) {
        category.name = name.trimmingCharacters(in: .whitespaces)
        category.type = selectedType
        category.updateAt = Date()
        
        saveContext()
        resetForm()
    }
    
    // MARK: - Xoá danh mục
    private func deleteCategory(_ category: Category) {
        context.delete(category)
        saveContext()
        resetForm()
    }
    
    // MARK: - Lưu context
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("❌ Lỗi khi lưu Category: \(error)")
        }
    }
    
    // Reset form
    private func resetForm() {
        name = ""
        editingCategory = nil
    }
}
