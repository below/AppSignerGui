//
//  Item+CoreDataProperties.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//
//

import Foundation
import CoreData


extension Item {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
        return NSFetchRequest<Item>(entityName: "Item")
    }

    @NSManaged public var timestamp: Date?
    @NSManaged public var packageName: PackageName?

}

extension Item : Identifiable {

}
