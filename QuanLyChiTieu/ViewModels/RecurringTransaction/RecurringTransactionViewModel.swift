//
//  RecurringTransactionViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 28/8/25.
//

import Foundation
import SwiftUI
import Combine

class RecurringTransactionViewModel: ObservableObject {
    @Published var recurringTransactions: [RecurringTransaction] = []
    @Published var isLoading = false
    
    private let repository = DataRepository.shared
    
    init() {
        loadRecurringTransactions()
    }
    
    func loadRecurringTransactions() {
        isLoading = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.recurringTransactions = self.repository.fetchRecurringTransactions()
            self.isLoading = false
        }
    }
    
    func addRecurringTransaction(
        title: String,
        amount: Double,
        type: String,
        categoryID: UUID?,
        frequency: RecurringFrequency,
        startDate: Date,
        endDate: Date? = nil,
        note: String? = nil
    ) {
        repository.addRecurringTransaction(
            title: title,
            amount: amount,
            type: type,
            categoryID: categoryID,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            note: note
        )
        loadRecurringTransactions()
    }
    
    func updateRecurringTransaction(
        _ recurring: RecurringTransaction,
        title: String? = nil,
        amount: Double? = nil,
        type: String? = nil,
        categoryID: UUID? = nil,
        frequency: RecurringFrequency? = nil,
        startDate: Date? = nil,
        endDate: Date?? = nil,
        note: String?? = nil
    ) {
        repository.updateRecurringTransaction(
            recurring,
            title: title,
            amount: amount,
            type: type,
            categoryID: categoryID,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            note: note
        )
        loadRecurringTransactions()
    }
    
    func deleteRecurringTransaction(_ recurring: RecurringTransaction) {
        repository.deleteRecurringTransaction(recurring)
        loadRecurringTransactions()
    }
    
    func toggleRecurringTransactionActive(_ recurring: RecurringTransaction) {
        repository.toggleRecurringTransactionActive(recurring)
        loadRecurringTransactions()
    }
    
    func processDueTransactions() {
        repository.processDueRecurringTransactions()
        loadRecurringTransactions()
    }
    
    var activeRecurringTransactions: [RecurringTransaction] {
        recurringTransactions.filter { $0.isActive && !$0.isExpired }
    }
    
    var dueRecurringTransactions: [RecurringTransaction] {
        activeRecurringTransactions.filter { $0.isDue }
    }
}

