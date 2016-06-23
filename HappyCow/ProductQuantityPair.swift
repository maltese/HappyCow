//
//  ProductQuantityPair.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 22/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import Foundation

/// A class representing a product-quantity pair.
class ProductQuantityPair {
    let product: Product
    var quantity: UInt = 0
    
    init(product: Product) {
        self.product = product
    }
}