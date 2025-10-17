//
//  Category+CoreDataProperties.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 15/10/25.
//
//

import Foundation 
import CoreData

extension Category {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }
    @NSManaged public var createAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var type: String?
    @NSManaged public var updateAt: Date?
    @NSManaged public var iconName: String?
    @NSManaged public var transactions: NSSet?
}

extension Category {
    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: Transaction)
    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: Transaction)
    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)
    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)
}
extension Category : Identifiable {
}
