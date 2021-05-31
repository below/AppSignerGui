//
//  SigningScheme+CoreDataProperties.swift
//  AppSignerGui
//
//  Created by Axel Schwarz on 28.05.21.
//
//

import Foundation
import CoreData


extension SigningScheme {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SigningScheme> {
        return NSFetchRequest<SigningScheme>(entityName: "SigningScheme")
    }

    @NSManaged public var value: Int16
    @NSManaged public var packageName: PackageName?

}

extension SigningScheme : Identifiable {

}
