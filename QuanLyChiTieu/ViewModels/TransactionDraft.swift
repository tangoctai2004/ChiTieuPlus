//
//  TransactionDraft.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 17/10/25.
//
import SwiftUI
import CoreData

class TransactionDraft: ObservableObject {
    @Published var transactionTitle: String = ""
    @Published var note: String = ""
    @Published var rawAmount: String = ""
    @Published var formattedAmount: String = ""
    @Published var date: Date = Date()
    @Published var type: String = "expense" {
        didSet {
            if oldValue != type {
                selectedCategory = nil
            }
        }
    }
    @Published var selectedCategory: Category?

    func reset() {
        transactionTitle = ""
        note = ""
        rawAmount = ""
        formattedAmount = ""
        date = Date()
        selectedCategory = nil
    }
}
