import Foundation
import Combine
import CoreData

class TransactionViewModel: ObservableObject {
    @Published var allTransactions: [Transaction] = []
    
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: DataRepository = .shared) {
        self.repository = repository
        
        // --- SỬA LỖI TỪ .assign SANG .sink ---
        repository.transactionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedTransactions in
                // Gán giá trị thủ công để đảm bảo @Published được kích hoạt
                self?.allTransactions = updatedTransactions
            }
            .store(in: &cancellables)
        // --- HẾT SỬA LỖI ---
            
        repository.fetchTransactions()
    }
    
    func fetchTransactions() {
        repository.fetchTransactions()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        repository.deleteTransaction(transaction)
    }
}
