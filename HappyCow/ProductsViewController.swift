//
//  ViewController.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 18/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import UIKit

class ProductsViewController: UITableViewController, ProductTableViewCellDelegate {
    // MARK: Model
    
    private let shoppingBasket: ShoppingBasket = {
        let shoppingBasket = ShoppingBasket()
        
        let products = ProductController.sharedInstance.products()
        for product in products {
            shoppingBasket.addProductQuantityPair(ProductQuantityPair(product: product))
        }
        
        return shoppingBasket
    }()
    
    // MARK: View
    
    @IBOutlet private weak var checkoutBarButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.registerNib(UINib(nibName: String(ProductTableViewCell), bundle: NSBundle(forClass: self.dynamicType)), forCellReuseIdentifier: String(ProductTableViewCell))
    }
    
    @IBAction func checkout() {
        self.navigationController?.pushViewController(CheckoutViewController(shoppingBasket: self.shoppingBasket), animated: true)
    }

    
    // MARK: UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.shoppingBasket.productQuantityPairCount()
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(String(ProductTableViewCell), forIndexPath: indexPath) as! ProductTableViewCell
        cell.delegate = self
        cell.productQuantityPair = self.shoppingBasket.productQuantityPairAtIndex(indexPath.row)
        return cell
    }
    
    // MARK: ProductTableViewCellDelegate

    func productTableViewCell(productTableViewCell: ProductTableViewCell, didUpdateQuantity: UInt) {
        self.checkoutBarButtonItem.enabled = shoppingBasket.totalPriceInUSD() != NSDecimalNumber.zero()
    }
}

