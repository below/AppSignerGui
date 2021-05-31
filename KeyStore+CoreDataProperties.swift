//
//  KeyStore+CoreDataProperties.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//
//

import Foundation
import CoreData


extension KeyStore {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeyStore> {
        return NSFetchRequest<KeyStore>(entityName: "KeyStore")
    }

    @NSManaged public var link: String?
    @NSManaged public var packageName: PackageName?

}

extension KeyStore : Identifiable {

}
