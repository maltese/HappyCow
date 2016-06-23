//
//  ProductTableViewCell.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 22/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import UIKit

class ProductTableViewCell: UITableViewCell {
    // MARK: Model
    
    var productQuantityPair: ProductQuantityPair? {
        didSet(productQuantityPair) {
            self.updateView()
        }
    }
    
    weak var delegate: ProductTableViewCellDelegate?
    
    // MARK: View
    
    @IBOutlet private weak var productNameLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var quantityLabel: UILabel!
    
    // MARK: Other
    
    private static let numberFormatter: NSNumberFormatter = {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.minimumIntegerDigits = 1
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        return numberFormatter
    }()

    private func updateView() {
        if let productQuantityPair = self.productQuantityPair {
            let product = productQuantityPair.product
            self.productNameLabel.text = product.name
            let formattedPrice = self.dynamicType.numberFormatter.stringFromNumber(product.pricePerUnitInUSD)!
            self.priceLabel.text = NSString(format: NSLocalizedString("$ %@ per %@", comment: "Price per unit label."), formattedPrice, product.unit) as String
            self.quantityLabel.text = String(productQuantityPair.quantity)
        }
    }
    
    @IBAction private func quantityChanged(stepper: UIStepper) {
        let stepperValue = UInt(stepper.value)
        
        // Update the model.
        self.productQuantityPair?.quantity = stepperValue
        
        // Update the view.
        self.updateView()
        
        // Inform the delegate
        self.delegate?.productTableViewCell(self, didUpdateQuantity: stepperValue)
    }
}

protocol ProductTableViewCellDelegate: class {
    func productTableViewCell(productTableViewCell: ProductTableViewCell, didUpdateQuantity: UInt)
}