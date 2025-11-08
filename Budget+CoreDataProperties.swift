//
//  Budget+CoreDataProperties.swift
//  QuanLyChiTieu
//
//  Created by Tạ Ngọc Tài on 8/11/25.
//
//

public import Foundation
public import CoreData


public typealias BudgetCoreDataPropertiesSet = NSSet

extension Budget {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Budget> {
        return NSFetchRequest<Budget>(entityName: "Budget")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var month: Int16
    @NSManaged public var year: Int16
    @NSManaged public var category: Category?

}

extension Budget : Identifiable {

}
