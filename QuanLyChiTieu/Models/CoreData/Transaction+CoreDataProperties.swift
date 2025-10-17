//
//  Transaction+CoreDataProperties.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 27/8/25.
//
//

import Foundation
import CoreData


extension Transaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }
    @NSManaged public var amount: Double
    @NSManaged public var createAt: Date?
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var note: String?
    @NSManaged public var title: String?
    @NSManaged public var type: String?
    @NSManaged public var updateAt: Date?
    @NSManaged public var category: Category?
}
extension Transaction : Identifiable {
}
