//
//  KeyPass+CoreDataProperties.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//
//

import Foundation
import CoreData


extension KeyPass {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyPass> {
        return NSFetchRequest<KeyPass>(entityName: "KeyPass")
    }

    @NSManaged public var pass: String?
    @NSManaged public var packageName: PackageName?

}

extension KeyPass : Identifiable {

}
