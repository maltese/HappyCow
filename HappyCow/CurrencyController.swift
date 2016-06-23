//
//  CurrencyController.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 18/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import Foundation
import RestKit

class CurrencyController {
    static let sharedInstance = CurrencyController()
    
    enum Error: ErrorType {
        case FetchError(underlyingError: NSError)
    }
    
    private static let coreDataModelName = "CurrencyModels"
    private static let baseURL = "http://apilayer.net/api/"
    private static let exchangeRatePath = "live"

    private let cacheStorageIdentifier: String
    private let lastSuccessfulExchangeRateFetchKey: String
    private let cacheValidityPeriod: NSTimeInterval
    private let APIKey: String
    private lazy var defaultParameters: [String: String] = { ["access_key": self.APIKey] }()
    
    init(cacheStorageIdentifier: String = "CurrencyModelCache", cacheValidityPeriod: NSTimeInterval = 6 * 3600 /* 6 hours. */, APIKey: String = "4647d28ab69ff6c8d297c1fc2b76651d") {
        self.cacheStorageIdentifier = cacheStorageIdentifier
        self.lastSuccessfulExchangeRateFetchKey = "lastSuccessfulExchangeRateFetchFor\(self.cacheStorageIdentifier)"
        self.cacheValidityPeriod = cacheValidityPeriod
        self.APIKey = APIKey
        
        self.setupResponseDescriptors()
        self.setupFetchRequestBlock()
        
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true
    }
    
    /// Gets the exchange rates.
    func exchangeRates(success: (results: [ExchangeRate]) -> Void, failure: (error: Error) -> Void) -> CurrencyControllerRequestHandle {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        if let lastSuccessfulExchangeRateFetch = userDefaults.objectForKey(self.lastSuccessfulExchangeRateFetchKey) as? NSDate where NSDate().timeIntervalSinceDate(lastSuccessfulExchangeRateFetch) <= self.cacheValidityPeriod {
            return self.exchangeRatesFromLocal(success, failure: failure)
        } else {
            return self.exchangeRatesFromRemote({ (results) in
                userDefaults.setObject(NSDate(), forKey: self.lastSuccessfulExchangeRateFetchKey)
                success(results: results)
            }, failure: failure)
        }
    }
    
    /// Gets the currencies.
    func currencies(success: (results: [String]) -> Void, failure: (error: Error) -> Void) -> CurrencyControllerRequestHandle {
        return self.exchangeRates({ (results) in
            success(results: results.map { $0.currency! })
            }, failure: failure)
    }
    
    /// Invalidates the cache.
    func invalidateCache() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(self.lastSuccessfulExchangeRateFetchKey)
    }
    
    private func exchangeRatesFromRemote(success: (results: [ExchangeRate]) -> Void, failure: (error: Error) -> Void) -> CurrencyControllerRequestHandle {
        let operation = self.objectManager.appropriateObjectRequestOperationWithObject(nil, method: .GET, path: self.dynamicType.exchangeRatePath, parameters: self.defaultParameters) as! RKObjectRequestOperation
        operation.setCompletionBlockWithSuccess({ (operation, mappingResult) in
            let results = mappingResult.array() as! [ExchangeRate]
            success(results: results.sort {$0.currency! < $1.currency!})
        }) { (operation, error) in
            if !(error.domain == RKErrorDomain && error.code == RKRestKitError.OperationCancelledError.rawValue) {
                failure(error: Error.FetchError(underlyingError: error))
            }
        }
        self.objectManager.enqueueObjectRequestOperation(operation)
        return operation
    }
    
    private func exchangeRatesFromLocal(success: (results: [ExchangeRate]) -> Void, failure: (error: Error) -> Void) -> CurrencyControllerRequestHandle {
        let operation = NSBlockOperation { 
            let fetchRequest = NSFetchRequest(entityName: String(ExchangeRate))
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "currency", ascending: true)]
            do {
                success(results: try self.objectManager.managedObjectStore.mainQueueManagedObjectContext.executeFetchRequest(fetchRequest) as! [ExchangeRate])
            } catch let error {
                failure(error: Error.FetchError(underlyingError: error as NSError))
            }
        }
        NSOperationQueue.mainQueue().addOperation(operation)
        return LocalCurrencyControllerRequestHandle(operation: operation)
    }
    
    private lazy var objectManager: RKObjectManager = {
        let coreDataModelURL = NSURL(string: NSBundle(forClass: self.dynamicType).pathForResource(self.dynamicType.coreDataModelName, ofType: "momd")!)!
        let managedObjectModel = NSManagedObjectModel(contentsOfURL: coreDataModelURL)
        let managedObjectStore = RKManagedObjectStore(managedObjectModel: managedObjectModel)
        let applicationDocumentsDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let url = applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.cacheStorageIdentifier).sqlite")
        do {
            try managedObjectStore.addSQLitePersistentStoreAtPath(url.path, fromSeedDatabaseAtPath: nil, withConfiguration: nil, options: nil)
        } catch let error {
            print(error)
            fatalError()
        }
        managedObjectStore.createManagedObjectContexts()
        let objectManager = RKObjectManager(baseURL: NSURL(string: self.dynamicType.baseURL)!)
        objectManager.managedObjectStore = managedObjectStore
        
        return objectManager
    }()
    
    private func setupResponseDescriptors() {
        let exchangeRateMapping = ExchangeRate.mapping(forManagedObjectStore: self.objectManager.managedObjectStore)
        let responseDescriptor = RKResponseDescriptor(mapping: exchangeRateMapping, method: .GET, pathPattern: self.dynamicType.exchangeRatePath, keyPath: "quotes", statusCodes: RKStatusCodeIndexSetForClass(.Successful))
        self.objectManager.addResponseDescriptor(responseDescriptor)
    }
    
    private func setupFetchRequestBlock() {
        var parsedArguments: NSDictionary?
        self.objectManager.addFetchRequestBlock { (URL) -> NSFetchRequest! in
            let pathMatcher = RKPathMatcher(pattern: self.dynamicType.exchangeRatePath)
            let match = pathMatcher.matchesPath(URL.relativePath, tokenizeQueryStrings: false, parsedArguments: &parsedArguments)
            if (match) {
                return NSFetchRequest(entityName: String(ExchangeRate))
            }
            return nil
        }
        
    }
}

protocol CurrencyControllerRequestHandle {
    /// Cancels the request.
    func cancel() -> Void
}

extension RKObjectRequestOperation: CurrencyControllerRequestHandle {}

private class LocalCurrencyControllerRequestHandle: CurrencyControllerRequestHandle {
    private let operation: NSOperation
    
    init(operation: NSOperation) {
        self.operation = operation
    }
    
    func cancel() {
        self.operation.cancel()
    }
}