//
//  CurrencyControllerTests.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 19/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import XCTest
import OHHTTPStubs

/// Unit tests for `CurrencyController`.
class CurrencyControllerTests: XCTestCase {
    /// The API URL to stub.
    private static let currencyAPIURL = NSURL(string: "http://apilayer.net/api/live?access_key=4647d28ab69ff6c8d297c1fc2b76651d")!
    
    /// The default amount of time to wait before a test should time out.
    private static let defaultExpectationTimeout = 1 as NSTimeInterval
    
    private static let successfulResponseJSONFileName = "successfulResponse.json"
    private static let successfulResponse2JSONFileName = "successfulResponse2.json"
    private static let internalServerErrorResponseJSONFileName = "internalServerErrorResponse.json"
    private static let invalidJSONResponseJSONFileName = "invalidJSONResponse.json"
    private static let errorMessageResponseJSONFileName = "errorMessageResponse.json"
    private static let someInvalidQuotesResponseJSONFileName = "someInvalidQuotesResponse.json"
    
    override func setUp() {
        super.setUp()

        // Enable the interception of HTTP calls.
        OHHTTPStubs.setEnabled(true)
    }
    
    override func tearDown() {
        // Disable the interception of HTTP calls and remove all previously added stubs.
        OHHTTPStubs.setEnabled(false)
        
        super.tearDown()
    }
    
    /// Tests a successful response.
    func testSuccessfulResponse() {
        self.stubResponse(self.dynamicType.successfulResponseJSONFileName)
        
        let expectation = expectationWithDescription("Request finishes.")
        
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            self.checkValidityOfSuccessfulResponse(self.dynamicType.successfulResponseJSONFileName, forResults: results)
            expectation.fulfill()
        }) { (error) in
            XCTFail(String(error))
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }
    
    /// Tests that the data comes from the cache if a second request is made before the cache expires.
    func testSuccessfulCachedResponse() {
        let stub = self.stubResponse(self.dynamicType.successfulResponseJSONFileName)
        
        let expectation = expectationWithDescription("Request finishes.")
        
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            // Simulate data changing on the server.
            OHHTTPStubs.removeStub(stub)
            self.stubResponse("successfulResponse2.json")
            // Execute another request.
            currencyController.exchangeRates({ (results) in
                // Test that the returned data is the cached one.
                self.checkValidityOfSuccessfulResponse(self.dynamicType.successfulResponseJSONFileName, forResults: results)
                expectation.fulfill()
            }) { (error) in
                XCTFail(String(error))
                expectation.fulfill()
            }
        }) { (error) in
            XCTFail(String(error))
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }
    
    /// Tests that the cache expires currectly and that a new remote fetch request is made if the cache is expired.
    func testCacheExpiration() {
        let stub = self.stubResponse(self.dynamicType.successfulResponseJSONFileName)
        
        let expectation = expectationWithDescription("Request finishes.")
        
        let cacheValidityPeriod = 0.1
        let currencyController = CurrencyController(cacheValidityPeriod: cacheValidityPeriod)
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            // Simulate data changing on the server.
            OHHTTPStubs.removeStub(stub)
            self.stubResponse(self.dynamicType.successfulResponse2JSONFileName)
            // Execute another request after a delay big enought to invalidate the cache.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64((cacheValidityPeriod + 0.3) * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                currencyController.exchangeRates({ (results) in
                    // Test that the returned data is not the cached one, but the fresh new data.
                    self.checkValidityOfSuccessfulResponse(self.dynamicType.successfulResponse2JSONFileName, forResults: results)
                    expectation.fulfill()
                }) { (error) in
                    XCTFail(String(error))
                    expectation.fulfill()
                }
            })
        }) { (error) in
            XCTFail(String(error))
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(2 * self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }
    
    /// Tests the neither the `success` nor the `failure` callback are called if the (remote) request is cancelled.
    func testCancellationOfRemoteRequest() {
        let expectation = expectationWithDescription("Request finishes.")
        
        self.stubResponse(self.dynamicType.successfulResponseJSONFileName)
        
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        let request = currencyController.exchangeRates({ (results) in
            XCTFail()
        }) { (error) in
            XCTFail()
        }
        request.cancel()

        // Give some time to the request to potentially finish.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.75 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            expectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }

    /// Tests the neither the `success` nor the `failure` callback are called if the (local) request is cancelled.
    func testCancellationOfLocalRequest() {
        let expectation = expectationWithDescription("Request finishes.")
        
        self.stubResponse(self.dynamicType.successfulResponseJSONFileName)
        
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            let request = currencyController.exchangeRates({ (results) in
                XCTFail()
            }) { (error) in
                XCTFail()
            }
            request.cancel()
        }) { (error) in
            XCTFail()
        }
        
        // Give some time to the request to potentially finish.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.75 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            expectation.fulfill()
        })
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }
    
    /// Tests that the `failure` callback is called when the server returns a non-2XX status code.
    func testNon2XXStatusCodeResponse() {
        let expectation = expectationWithDescription("Request finishes.")

        self.stubResponse(self.dynamicType.internalServerErrorResponseJSONFileName, statusCode: 500)
        
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            XCTFail()
            expectation.fulfill()
        }) { (error) in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }
    
    /// Tests that the `failure` callback is called with the correct NSError object when the connection to the Internet is absent.
    func testNotConnectedToTheInternetError() {
        let expectation = expectationWithDescription("Request finishes.")
        
        let notConnectedToTheInternetError = NSError(domain: NSURLErrorDomain, code: Int(CFNetworkErrors.CFURLErrorNotConnectedToInternet.rawValue), userInfo: nil)
        self.stubResponse(self.dynamicType.successfulResponseJSONFileName, error: notConnectedToTheInternetError)
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            XCTFail()
            expectation.fulfill()
        }) { (error) in
            if case CurrencyController.Error.FetchError(let underlyingError) = error {
                XCTAssertEqual(underlyingError.domain, notConnectedToTheInternetError.domain)
                XCTAssertEqual(underlyingError.code, notConnectedToTheInternetError.code)
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }
    
    /// Tests that the `failure` callback is called if the response is not valid JSON.
    func testInvalidJSONResponse() {
        let expectation = expectationWithDescription("Request finishes.")
        
        self.stubResponse(self.dynamicType.invalidJSONResponseJSONFileName)
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            XCTFail()
            expectation.fulfill()
        }) { (error) in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }
    
    /// Tests that the `failure` callback is called if the response is an API error message.
    func testErrorMessageResponse() {
        let expectation = expectationWithDescription("Request finishes.")
        
        self.stubResponse(self.dynamicType.errorMessageResponseJSONFileName)
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            XCTFail()
            expectation.fulfill()
        }) { (error) in
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }
    
    /// Tests that the `results` only contain valid quotes.
    func testSomeInvalidQuotesResponse() {
        let expectation = expectationWithDescription("Request finishes.")
        
        self.stubResponse(self.dynamicType.someInvalidQuotesResponseJSONFileName)
        let currencyController = CurrencyController()
        currencyController.invalidateCache()
        currencyController.exchangeRates({ (results) in
            XCTAssertEqual(results.count, 1)
            let exchangeRate = results[0]
            XCTAssertEqual(exchangeRate.currency, "CHF")
            XCTAssertEqual(exchangeRate.rate, NSDecimalNumber(string: "0.982599"))
            expectation.fulfill()
        }) { (error) in
            XCTFail()
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(self.dynamicType.defaultExpectationTimeout) { XCTAssertNil($0) }
    }

    /**
     Checks the validity of the results as per the response contained within `responseFileName`.
     
     - parameter responseFileName: The name of the json file containing the response.
     - parameter results: The results to check against the response.

     - precondition: The json file must exist and be a valid response.
     */
    private func checkValidityOfSuccessfulResponse(responseFileName: String, forResults results: [ExchangeRate]) {
        let responseFileNamePath = OHPathForFile(responseFileName, self.dynamicType)!
        let response = try! NSJSONSerialization.JSONObjectWithData(NSData(contentsOfFile: responseFileNamePath)!, options: []) as! NSDictionary
        let quotes = response["quotes"]! as! [String: Double]
        
        XCTAssertEqual(quotes.count, results.count)
        
        var sortedQuotes = [(currency: String, rate: Double)]()
        for (currencyPair, rate) in quotes {
            let extractedCurrency = currencyPair.substringFromIndex(currencyPair.startIndex.advancedBy(3))
            sortedQuotes.append((extractedCurrency, rate))
        }
        sortedQuotes.sortInPlace { $0.currency < $1.currency }
        
        for (index, quote) in sortedQuotes.enumerate() {
            XCTAssertEqual(quote.currency, results[index].currency)
            XCTAssertEqual(NSDecimalNumber(decimal: (quote.rate as NSNumber).decimalValue), results[index].rate)
        }
    }
    
    /**
     Stubs a response with the specified settings.
     
     - parameter responseFileName: The name of a file contained within the current bundle to return as part of the HTTP response.
     - parameter statusCode: The HTTP status code to return as part of the HTTP response.
     - parameter delay: The amount of time to wait before returning the request.
     - parameter error: If the error is non-`nil`, the request will result in a failure delivering the very same error passed.
     
     - returns: The stub descriptor.
     */
    private func stubResponse(responseFileName: String, statusCode: Int32 = 200, delay: NSTimeInterval = 0, error: NSError? = nil) -> OHHTTPStubsDescriptor {
        return stub({ ($0.HTTPMethod == "GET") && ($0.URL == self.dynamicType.currencyAPIURL) }) { (request) -> OHHTTPStubsResponse in
            let response = fixture(OHPathForFile(responseFileName, self.dynamicType)!, headers: ["Content-Type": "application/json"])
            if let error = error {
                response.error = error
            } else {
                response.statusCode = statusCode
                response.responseTime = delay
            }
            return response
        }
    }

    
}
