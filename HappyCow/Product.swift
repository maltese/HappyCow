//
//  Product.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 22/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import Foundation

class Product {
    let name: String
    let unit: String
    let pricePerUnitInUSD: NSDecimalNumber
    
    init(name: String, unit: String, pricePerUnitInUSD: NSDecimalNumber) {
        self.name = name
        self.unit = unit
        self.pricePerUnitInUSD = pricePerUnitInUSD
    }
    
    /**
     Initializes the object with a dictionary containing this object's properties as keys.
     
     - Parameter dictionary: The dictionary.
     
     - Precondition: The dictionary must be valid.
     */
    convenience init(dictionary: NSDictionary) {
        self.init(name: dictionary["name"] as! String, unit: dictionary["unit"] as! String, pricePerUnitInUSD: NSDecimalNumber(decimal: (dictionary["pricePerUnitInUSD"] as! NSNumber).decimalValue))
    }
}