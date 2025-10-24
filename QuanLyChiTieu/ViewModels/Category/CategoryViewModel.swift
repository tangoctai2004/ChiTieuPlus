import Foundation
import Combine
import CoreData

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: DataRepository = .shared) {
        self.repository = repository
        
        repository.categoriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedCategories in
                self?.categories = updatedCategories
            }
            .store(in: &cancellables)
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
