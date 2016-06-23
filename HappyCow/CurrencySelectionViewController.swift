//
//  CurrencySelectionViewController.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 23/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import UIKit

class CurrencySelectionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private static let cellIdentifier = "cellIdentifier"
    
    private var currencies: [String]?
    
    @IBOutlet private weak var tableView: UITableView!
    private var activityView: ActivityView!
    
    var selectedCurrency: String = "USD"
    
    weak var delegate: CurrencySelectionViewControllerDelegate?
    
    init() {
        super.init(nibName: nil, bundle: NSBundle(forClass: self.dynamicType))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityView = ActivityView.newInstance()
        self.view.addSubview(self.activityView)
        self.activityView.frame = self.view.bounds
        self.activityView.retry = { self.loadCurrencies() }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.loadCurrencies()
        
        super.viewWillAppear(animated)
    }
    
    func loadCurrencies() {
        self.activityView.hidden = false
        self.activityView.showActivityIndicator()

        CurrencyController.sharedInstance.currencies({[weak self] results in
            self?.currencies = results
            self?.tableView.reloadData()
            
            self?.activityView.hidden = true
        }) {[weak self] error in
            switch error {
            case let .FetchError(underlyingError):
                self?.activityView.showError(NSLocalizedString("Could not fetch currencies", comment: "Error message"), networkError: underlyingError)
            }
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currencies = self.currencies {
            return currencies.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(self.dynamicType.cellIdentifier)
        if (cell == nil) {
            cell = UITableViewCell(style: .Default, reuseIdentifier: self.dynamicType.cellIdentifier)
        }
        let currency = self.currencies![indexPath.row]
        cell?.textLabel?.text = currency
        cell?.accessoryType = self.selectedCurrency == currency ? .Checkmark : .None
        return cell!
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.delegate?.currencySelectionViewController(self, didSelectCurrency: self.currencies![indexPath.row])
    }
}


protocol CurrencySelectionViewControllerDelegate: class {
    func currencySelectionViewController(currencySelectionViewController: CurrencySelectionViewController, didSelectCurrency currency: String)
}