//
//  CategoryListScreen.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 15/10/25.
//

import SwiftUI
import CoreData

struct CategoryListScreen: View {
    // SỬA ĐỔI: Khởi tạo viewModel bằng context lấy từ Environment.
    // Dòng @StateObject này giờ sẽ đảm bảo ViewModel dùng chung context
    // với toàn bộ ứng dụng.
    @StateObject private var viewModel: CategoryViewModel

    // Thêm hàm init để nhận context từ bên ngoài vào
    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: CategoryViewModel(context: context))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1), Color.orange.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    Section(header: Text("Chi tiêu").fontWeight(.bold)) {
                        ForEach(viewModel.categories.filter { $0.type == "expense" }) { category in
                            // `CategoryEditScreen` và `CategoryAddScreen` sẽ tự động hoạt động đúng
                            // vì chúng nhận `viewModel` đã được khởi tạo chính xác ở đây.
                            NavigationLink(destination: CategoryEditScreen(viewModel: viewModel, category: category)) {
                                CategoryRow(category: category)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                    
                    Section(header: Text("Thu nhập").fontWeight(.bold)) {
                        ForEach(viewModel.categories.filter { $0.type == "income" }) { category in
                            NavigationLink(destination: CategoryEditScreen(viewModel: viewModel, category: category)) {
                                CategoryRow(category: category)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Danh mục")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CategoryAddScreen(viewModel: viewModel)) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }
}

// Struct CategoryRow không cần thay đổi
struct CategoryRow: View {
    @ObservedObject var category: Category
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: category.iconName ?? "questionmark.circle")
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            Text(category.name ?? "Không có tên")
                .font(.system(.headline, design: .rounded))
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.vertical, 4)
    }
}
