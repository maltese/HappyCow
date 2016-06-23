//
//  RetryView.swift
//  HappyCow
//
//  Created by Matteo Cortonesi on 23/06/16.
//  Copyright © 2016 Matteo Cortonesi. All rights reserved.
//

import UIKit

/// A view to be used as a temporary place holder when loading data.
class ActivityView: UIView {
    // MARK: Model
    
    var retry: (() -> Void)?
    
    private static let generalErrorMessage = NSLocalizedString("There was a problem communicating with HappyCow.", comment: "General error message")
    private static let noInternetConnection = NSLocalizedString("You do not seem to be online. Connect to the Internet and try again?", comment: "Not connected to the internet error message.")
    
    // MARK: View
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var errorMessageLabel: UILabel!
    @IBOutlet private weak var detailedErrorMessageLabel: UILabel!
    @IBOutlet private weak var tryAgainButton: UIButton!
    
    static func newInstance() -> ActivityView {
        let activityView = UINib(nibName: String(self), bundle: NSBundle(forClass: self)).instantiateWithOwner(nil, options: nil)[0] as! ActivityView
        activityView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        return activityView
    }

    func showError(message: String, networkError: NSError) {
        self.errorMessageLabel.text = message
        if (networkError.domain == NSURLErrorDomain) && (networkError.code == Int(CFNetworkErrors.CFURLErrorNotConnectedToInternet.rawValue)) {
            self.detailedErrorMessageLabel.text = self.dynamicType.noInternetConnection
        } else {
            self.detailedErrorMessageLabel.text = self.dynamicType.generalErrorMessage
        }

        self.toggleVisibility(false)
    }
    
    func showActivityIndicator() {
        self.toggleVisibility(true)
    }
    
    private func toggleVisibility(flag: Bool) {
        self.activityIndicatorView.hidden = !flag

        self.imageView.hidden = flag
        self.errorMessageLabel.hidden = flag
        self.detailedErrorMessageLabel.hidden = flag
        self.tryAgainButton.hidden = flag
    }
    
    @IBAction private func tryAgainButtonTapped() {
        self.retry?()
    }
    
}
