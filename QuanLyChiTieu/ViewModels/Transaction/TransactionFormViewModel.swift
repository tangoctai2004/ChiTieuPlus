//
//  TransactionFormViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 17/10/25.
//

import Foundation
import CoreData

class TransactionFormViewModel: ObservableObject {
    @Published var transactionTitle: String = ""
    @Published var note: String = ""
    @Published var rawAmount: String = ""
    @Published var formattedAmount: String = ""
    @Published var date: Date = Date()
    @Published var type: String = "expense" {
        didSet {
            if oldValue != type {
                selectedCategory = nil
                selectedCategoryID = nil
            }
        }
    }
    @Published var selectedCategoryID: NSManagedObjectID?
    
    @Published var selectedCategory: Category?
    
    private var transactionToEdit: Transaction?
    private let repository: DataRepository
    
    var isEditing: Bool {
        transactionToEdit != nil
    }
    
    var canSave: Bool {
        AppUtils.currencyToDouble(rawAmount) > 0 && selectedCategoryID != nil
    }
    
    init(repository: DataRepository = .shared, transaction: Transaction? = nil) {
        self.repository = repository
        self.transactionToEdit = transaction
        
        reinitializeFromTransaction()
    }
    
    func reinitializeFromTransaction() {
        if let transaction = transactionToEdit {
            self.transactionTitle = transaction.title ?? ""
            self.note = transaction.note ?? ""
            self.date = transaction.date ?? Date()
            self.type = transaction.type ?? "expense"
            
            self.selectedCategory = transaction.category
            self.selectedCategoryID = transaction.category?.objectID
            
            let initialRawAmount = String(Int(transaction.amount))
            self.rawAmount = initialRawAmount
            self.formattedAmount = AppUtils.formatCurrencyInput(initialRawAmount)
        }
    }
    
    func save() {
        let formData = TransactionFormData(
            transactionTitle: transactionTitle,
            note: note,
            rawAmount: rawAmount,
            date: date,
            type: type,
            selectedCategoryID: selectedCategoryID
        )
        
        if let transaction = transactionToEdit {
            repository.updateTransaction(transaction, formData: formData)
        } else {
            repository.addTransaction(formData: formData)
        }
    }
    
    func delete() {
        if let transaction = transactionToEdit {
            repository.deleteTransaction(transaction)
        }
    }

    func reset() {
        transactionTitle = ""
        note = ""
        rawAmount = ""
        formattedAmount = ""
        date = Date()
        selectedCategory = nil
        selectedCategoryID = nil
    }
}
