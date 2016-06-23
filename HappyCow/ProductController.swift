//
//  ProductController.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 22/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import UIKit

class ProductController: NSObject {
    static let sharedInstance = ProductController()
    
    private let plistFileName: String
    
    init(plistFileName: String = "Products") {
        self.plistFileName = plistFileName
    }
    
    /**
     Returns all the products.
     
     - Precondition: A valid `\(plistFileName).plist` file of the form `[{name: "ProductName", unit: "productUnit", pricePerUnitInUSD: 1.23}]` must be present in the current bundle.
     
     - Returns: An array of product objects.
     */
    func products() -> [Product] {
        let productPlistPath = NSBundle(forClass: self.dynamicType).pathForResource(self.plistFileName, ofType: "plist")!
        let productDictionary = NSArray(contentsOfFile: productPlistPath)!
        return productDictionary.map { Product(dictionary: $0 as! NSDictionary) }
    }
}
