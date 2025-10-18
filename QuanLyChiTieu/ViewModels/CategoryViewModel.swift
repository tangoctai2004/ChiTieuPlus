import Foundation
import Combine
import CoreData

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: DataRepository = .shared) {
        self.repository = repository
        
        // --- SỬA LỖI TỪ .assign SANG .sink ---
        repository.categoriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedCategories in
                // Gán giá trị thủ công để đảm bảo @Published được kích hoạt
                self?.categories = updatedCategories
            }
            .store(in: &cancellables)
        // --- HẾT SỬA LỖI ---
    }
    
    func fetchAllCategories() {
        repository.fetchCategories()
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
