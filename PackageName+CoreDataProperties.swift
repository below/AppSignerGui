//
//  PackageName+CoreDataProperties.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//
//

import Foundation
import CoreData


extension PackageName {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PackageName> {
        return NSFetchRequest<PackageName>(entityName: "PackageName")
    }

    @NSManaged public var package: String?
    @NSManaged public var appName: AppName?
    @NSManaged public var item: Item?
    @NSManaged public var keyPass: KeyPass?
    @NSManaged public var keyStore: KeyStore?
    @NSManaged public var signingScheme: SigningScheme?

}

extension PackageName : Identifiable {

}
