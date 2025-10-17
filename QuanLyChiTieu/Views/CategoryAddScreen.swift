//
//  CategoryAddScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 15/10/25.
//

import SwiftUI

struct CategoryAddScreen: View {
    // Nhận ViewModel từ màn hình trước
    @ObservedObject var viewModel: CategoryViewModel
    
    // Environment để đóng màn hình sau khi lưu
    @Environment(\.dismiss) private var dismiss
    
    // Các State để lưu dữ liệu form
    @State private var name: String = ""
    @State private var selectedType: String = "expense"
    @State private var selectedIconName: String = "cart.fill" // Chọn một icon làm mặc định
    
    // Danh sách icon mẫu (bạn có thể mở rộng)
    let iconList = ["cart.fill", "house.fill", "airplane", "gift.fill", "banknote.fill", "phone.fill", "fork.knife", "pills.fill"]
    
    var body: some View {
        // MARK: - Thêm ZStack và Gradient
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1), Color.orange.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
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
                    // Lưới hiển thị các icon để chọn
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))]) {
                        ForEach(iconList, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title)
                                .padding(8)
                                .background(selectedIconName == icon ? Color.accentColor.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedIconName = icon
                                }
                        }
                    }
                }
            }
            // MARK: - Làm trong suốt nền của Form
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Thêm mới")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Lưu") {
                    // Gọi hàm addCategory từ ViewModel
                    viewModel.addCategory(name: name, type: selectedType, iconName: selectedIconName)
                    // Đóng màn hình
                    dismiss()
                }
                // Nút Lưu bị vô hiệu hoá nếu chưa nhập tên
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
