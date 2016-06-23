//
//  ShoppingBasket.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 22/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import Foundation

class ShoppingBasket {
    private var productQuantityPairs = [] as [ProductQuantityPair]
    
    func addProductQuantityPair(productQuantityPair: ProductQuantityPair) {
        self.productQuantityPairs.append(productQuantityPair)
    }
    
    func productQuantityPairAtIndex(index: Int) -> ProductQuantityPair {
        return self.productQuantityPairs[index]
    }
    
    subscript(index: Int) -> ProductQuantityPair {
        return self.productQuantityPairAtIndex(index)
    }
    
    func productQuantityPairCount() -> Int {
        return self.productQuantityPairs.count
    }
    
    func totalPriceInUSD() -> NSDecimalNumber {
        return self.productQuantityPairs.reduce(NSDecimalNumber.zero()) {
            $0.decimalNumberByAdding($1.product.pricePerUnitInUSD.decimalNumberByMultiplyingBy(NSDecimalNumber(decimal: ($1.quantity as NSNumber).decimalValue)))
        }
    }
    
    enum Error: ErrorType {
        case InvalidCurrency(currency: String)
        case Other(underlyingError: CurrencyController.Error)
    }
    
    func totalPrice(forCurrency currency: String, success: (result: NSDecimalNumber) -> Void, failure: (error: Error) -> Void) -> CurrencyControllerRequestHandle {
        return CurrencyController.sharedInstance.exchangeRates({ (results) in
            let filteredResults = results.filter { $0.currency == currency }
            if (filteredResults.count > 0) {
                let matchingExchangeRate = filteredResults.first!
                let totalPrice = matchingExchangeRate.rate!.decimalNumberByMultiplyingBy(self.totalPriceInUSD())
                success(result: totalPrice)
            } else {
                failure(error: Error.InvalidCurrency(currency: currency))
            }
        }, failure: { (error) in
            failure(error: Error.Other(underlyingError: error))
        })
    }
}