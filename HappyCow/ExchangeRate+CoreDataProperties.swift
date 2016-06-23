//
//  ExchangeRate+CoreDataProperties.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 20/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ExchangeRate {

    @NSManaged var currency: String?
    @NSManaged var rate: NSDecimalNumber?

}
