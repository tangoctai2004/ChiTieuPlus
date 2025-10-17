//
//  TransactionViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 17/10/25.
//

import Foundation
import Combine
import CoreData

class TransactionViewModel: ObservableObject {
    @Published var allTransactions: [Transaction] = []
    
    private let repository: DataRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: DataRepository = .shared) {
        self.repository = repository
        
        repository.transactionsPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.allTransactions, on: self)
            .store(in: &cancellables)
    }
    
    func fetchTransactions() {
        repository.fetchTransactions()
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        repository.deleteTransaction(transaction)
    }
}
