//
//  AppName+CoreDataProperties.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//
//

import Foundation
import CoreData


extension AppName {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppName> {
        return NSFetchRequest<AppName>(entityName: "AppName")
    }

    @NSManaged public var name: String?
    @NSManaged public var packageName: PackageName?

}

extension AppName : Identifiable {

}
