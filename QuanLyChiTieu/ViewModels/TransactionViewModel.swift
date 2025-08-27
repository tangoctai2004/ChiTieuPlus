//
//  TransactionViewModel.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 27/8/25.
//

import Foundation
import CoreData
import Combine

class TransactionViewModel: ObservableObject{
//    Hien thi danh sach giao dich
    @Published var transactions: [Transaction] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.context){
        self.context = context
        fetchAllTransactions()
    }
    
    func fetchAllTransactions(){
        let request: NSFetchRequest<Transaction> = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Transaction.date, ascending: false)]
        do{
            transactions = try context.fetch(request)
        }catch{
            print("Lay du lieu that bai, loi: \(error)")
        }
    }
    
    func addTransaction(title: String, amount: Double, type: String, date: Date, note: String?, category: Category){
        let newTransaction = Transaction(context: context)
        newTransaction.id = UUID()
        newTransaction.title = title
        newTransaction.amount = amount
        newTransaction.type = type
        newTransaction.date = date
        newTransaction.note = note
        newTransaction.category = category
        newTransaction.createAt = Date()
        newTransaction.updateAt = Date()
        
        saveContext()
        fetchAllTransactions()
    }
    
    func deleteTransaction(_ transaction: Transaction){
        context.delete(transaction)
        
        saveContext()
        fetchAllTransactions()
    }
    
    func updateTransaction(_ transaction: Transaction, title: String, amount: Double, type: String, date: Date, note: String?, category: Category){
        transaction.title = title
        transaction.amount = amount
        transaction.type = type
        transaction.date = date
        transaction.note = note
        transaction.category = category
        transaction.updateAt = Date()
        
        saveContext()
        fetchAllTransactions()
    }
    
    private func saveContext(){
        if context.hashValue != 0{
            do{
                try context.save()
            }catch{
                print("Luu khong thanh cong, loi: \(error)")
            }
        }
    }
}

