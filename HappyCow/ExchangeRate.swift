//
//  ExchangeRate.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 20/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import Foundation
import CoreData
import RestKit

class ExchangeRate: NSManagedObject {
    enum ValidationError: ErrorType {
        case RateMustBeAnNSDecimalNumber
        case RateMustBeGreaterThanZero
        case CurrencyMustBeAString
        case CurrencyMustBeISO4217Compliant
    }
    
    /// KVC rate validation.
    func validateRate(value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let rate = value.memory as? NSDecimalNumber else {
            throw ValidationError.RateMustBeAnNSDecimalNumber
        }
        guard rate.compare(0) == .OrderedDescending else {
            throw ValidationError.RateMustBeGreaterThanZero
        }
    }
    
    /// KVC currency validation.
    func validateCurrency(value: AutoreleasingUnsafeMutablePointer<AnyObject?>) throws {
        guard let currency = value.memory as? String else {
            throw ValidationError.CurrencyMustBeAString
        }
        guard currency.characters.count == 3 else {
            throw ValidationError.CurrencyMustBeISO4217Compliant
        }
    }
    
    static let MappingErrorDomain = "\(String(ExchangeRate))MappingErrorDomain"
    
    enum MappingError: Int {
        case CurrencyPairIsNotAString
        case CurrencyPairIsNotISO4217Compliant
        case SourceCurrencyIsNotUSD
    }
    
    static func mapping(forManagedObjectStore managedObjectStore: RKManagedObjectStore) -> RKEntityMapping {
        let mapping = RKEntityMapping(forEntityForName: String(self), inManagedObjectStore: managedObjectStore)
        mapping.addAttributeMappingFromKeyOfRepresentationToAttribute("currency")
        let attributeMapping: RKAttributeMapping = mapping.attributeMappings.first as! RKAttributeMapping
        attributeMapping.valueTransformer = RKBlockValueTransformer(validationBlock: { (sourceClass, destinationClass) -> Bool in
            return sourceClass.isSubclassOfClass(NSString) && destinationClass.isSubclassOfClass(NSString)
        }) { (inputValue, outputValue, outputValueClass, error) -> Bool in
            guard let inputString = inputValue as? String else {
                error.memory = NSError(domain: self.MappingErrorDomain, code: MappingError.CurrencyPairIsNotAString.rawValue, userInfo: nil)
                return true
            }
            // Assume ISO 4217
            guard inputString.characters.count == 6 else {
                error.memory = NSError(domain: self.MappingErrorDomain, code: MappingError.CurrencyPairIsNotISO4217Compliant.rawValue, userInfo: nil)
                return true
            }
            // Make sure the source is USD.
            let center = inputString.startIndex.advancedBy(3)
            guard inputString.substringToIndex(center) == "USD" else {
                error.memory = NSError(domain: self.MappingErrorDomain, code: MappingError.SourceCurrencyIsNotUSD.rawValue, userInfo: nil)
                return true
            }
            outputValue.memory = inputString.substringFromIndex(center)
            return true
        }
        mapping.addAttributeMappingsFromDictionary([
            "{currency}": "rate"
            ])
        mapping.identificationAttributes = ["currency"]
        mapping.forceCollectionMapping = true
        
        return mapping
    }
}
