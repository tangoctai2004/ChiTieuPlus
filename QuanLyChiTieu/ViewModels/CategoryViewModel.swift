//
//  CategoryViewModel.swift
//  QuanLyChiTieu
//
//  Updated by Tạ Ngọc Tài on 17/10/25.
//

import Foundation
import Combine
import CoreData

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    
    // ViewModel giờ phụ thuộc vào Repository, không phải context
    init(repository: DataRepository = .shared) {
        self.repository = repository
        
        // Lắng nghe sự thay đổi từ publisher của repository
        repository.categoriesPublisher
            .receive(on: DispatchQueue.main) // Đảm bảo cập nhật UI trên main thread
            .assign(to: \.categories, on: self)
            .store(in: &cancellables)
    }
    
    func fetchAllCategories() {
        repository.fetchCategories() // Yêu cầu repository fetch dữ liệu
    }
    
    func addCategory(name: String, type: String, iconName: String) {
        repository.addCategory(name: name, type: type, iconName: iconName)
    }
    
    func updateCategory(_ category: Category, name: String, type: String, iconName: String) {
        repository.updateCategory(category, name: name, type: type, iconName: iconName)
    }
    
    func deleteCategory(_ category: Category) {
        repository.deleteCategory(category)
    }
}
