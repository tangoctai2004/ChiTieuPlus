//
//  CategoryEditScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 15/10/25.
//

import SwiftUI

struct CategoryEditScreen: View {
    @ObservedObject var viewModel: CategoryViewModel
    let category: Category
    
    @Environment(\.dismiss) private var dismiss
    
    // Các State được khởi tạo giá trị từ category được truyền vào
    @State private var name: String = ""
    @State private var selectedType: String = "expense"
    @State private var selectedIconName: String = ""
    
    let iconList = ["cart.fill", "house.fill", "airplane", "gift.fill", "banknote.fill", "phone.fill", "fork.knife", "pills.fill"]
    
    var body: some View {
        Form {
            Section(header: Text("Thông tin danh mục")) {
                TextField("Tên danh mục", text: $name)
                
                Picker("Loại", selection: $selectedType) {
                    Text("Chi tiêu").tag("expense")
                    Text("Thu nhập").tag("income")
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("Biểu tượng")) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
                    ForEach(iconList, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.title)
                            .padding(8)
                            .background(selectedIconName == icon ? Color.blue.opacity(0.3) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedIconName = icon
                            }
                    }
                }
            }
            
            Section {
                Button(role: .destructive) {
                    // Gọi hàm xoá từ ViewModel
                    viewModel.deleteCategory(category)
                    dismiss()
                } label: {
                    Label("Xoá danh mục này", systemImage: "trash.fill")
                }
            }
        }
        .navigationTitle("Chỉnh sửa")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cập nhật") {
                    // Gọi hàm cập nhật từ ViewModel
                    viewModel.updateCategory(category, name: name, type: selectedType, iconName: selectedIconName)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            // Gán giá trị ban đầu cho form khi view xuất hiện
            self.name = category.name ?? ""
            self.selectedType = category.type ?? "expense"
            self.selectedIconName = category.iconName ?? "questionmark.circle"
        }
    }
}
