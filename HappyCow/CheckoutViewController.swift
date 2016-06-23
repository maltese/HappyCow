//
//  CheckoutViewController.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 23/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import UIKit

class CheckoutViewController: UIViewController, CurrencySelectionViewControllerDelegate {
    let shoppingBasket: ShoppingBasket
    var selectedCurrency: String = "USD"
    
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var currencyButton: UIButton!
    
    init(shoppingBasket: ShoppingBasket) {
        self.shoppingBasket = shoppingBasket
        super.init(nibName: nil, bundle: NSBundle(forClass: self.dynamicType))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported.")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Checkout", comment: "Checkout Screen Title")
        
        self.currencyButton.setTitle(self.selectedCurrency, forState: .Normal)
        self.amountLabel.text = self.dynamicType.numberFormatter.stringFromNumber(self.shoppingBasket.totalPriceInUSD())
    }
    
    @IBAction private func currencyButtonTapped() {
        let viewController = CurrencySelectionViewController()
        viewController.delegate = self
        viewController.selectedCurrency = self.selectedCurrency
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func updateAmount(withCurrency currency: String) {
        self.shoppingBasket.totalPrice(forCurrency: currency, success: {[weak self] result in
            self?.amountLabel.text = self?.dynamicType.numberFormatter.stringFromNumber(result)
        }) { (error) in
            // TODO
        }
    }
    
    private static let numberFormatter: NSNumberFormatter = {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter
    }()
    
    // MARK: CurrencySelectionViewControllerDelegate
    
    func currencySelectionViewController(currencySelectionViewController: CurrencySelectionViewController, didSelectCurrency currency: String) {
        // Update the model.
        self.selectedCurrency = currency
        
        // Update the view.
        self.currencyButton.setTitle(currency, forState: .Normal)
        self.updateAmount(withCurrency: currency)
        
        self.navigationController?.popViewControllerAnimated(true)
    }
}
