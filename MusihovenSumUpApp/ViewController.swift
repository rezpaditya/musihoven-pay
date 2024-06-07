//
//  ViewController.swift
//  MusihovenSumUpApp
//
//  Created by Respa Aditya on 11/05/2024.
//

import SumUpSDK
import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var switchSkipReceiptScreen: UISwitch!
    
    private var appearCompleted = false

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: ganti warna logo musihoven (selain putih)
        updateLogoColor()
    }
    
    func updateLogoColor() {
        // TODO: workaround function to change the image color
        imageView.image = UIImage(named: "musihoven_logo")?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.lightGray
    }
    
    @IBAction func button1Pressed(_ sender: Any) {
        requestCheckout(string: "1")
    }
    
    @IBAction func button2Pressed(_ sender: Any) {
        requestCheckout(string: "5")
    }
    
    @IBAction func button3Pressed(_ sender: Any) {
        requestCheckout(string: "10")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !appearCompleted {
            appearCompleted = true
            presentLogin()
        }
    }
    
    private func presentLogin() {
        // present login UI and wait for completion block to update button states
        SumUpSDK.presentLogin(from: self, animated: true) { [weak self] (success: Bool, error: Error?) in
            print("Did present login with success: \(success). Error: \(String(describing: error))")

            guard error == nil else {
                // errors are handled within the SDK, there should be no need
                // for your app to display any error message
                return
            }
            
            self?.dummy()
//            self?.updateCurrency()
//            self?.updateButtonStates()
        }
    }
    
    private func dummy() {
        
    }
    
    fileprivate func showResult(string: String) {
        label?.text = string
        // fade in label
        UIView.animateKeyframes(withDuration: 3, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            let relativeDuration = TimeInterval(0.15)
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: relativeDuration) {
                self.label?.alpha = 1.0
            }
            UIView.addKeyframe(withRelativeStartTime: 1.0 - relativeDuration, relativeDuration: relativeDuration) {
                self.label?.alpha = 0.0
            }
        }, completion: nil)
    }
    
    fileprivate func requestCheckout(string: String) {
        SumUpSDK.prepareForCheckout()
        
        // ensure that we have a valid merchant
        guard let merchantCurrencyCode = SumUpSDK.currentMerchant?.currencyCode else {
            showResult(string: "not logged in")
            return
        }

        let totalText = string

        // create an NSDecimalNumber from the totalText
        // please be aware to not use NSDecimalNumber initializers inherited from NSNumber
        let total = NSDecimalNumber(string: totalText)
        guard total != NSDecimalNumber.zero else {
            return
        }

        // setup payment request
        let request = CheckoutRequest(total: total,
                                      title: "Rumah Surga",
                                      currencyCode: merchantCurrencyCode)

        // set screenOptions to skip if switch is set to on
        if let skip = switchSkipReceiptScreen?.isOn, skip {
            request.skipScreenOptions = .success
        }

        // the foreignTransactionID is an **optional** parameter and can be used
        // to retrieve a transaction from SumUp's API. See -[SMPCheckoutRequest foreignTransactionID]
//        request.foreignTransactionID = "your-unique-identifier-\(ProcessInfo.processInfo.globallyUniqueString)"

        SumUpSDK.checkout(with: request, from: self) { [weak self] (result: CheckoutResult?, error: Error?) in
            if let safeError = error as NSError? {
                print("error during checkout: \(safeError)")

                if (safeError.domain == SumUpSDKErrorDomain) && (safeError.code == SumUpSDKError.accountNotLoggedIn.rawValue) {
                    self?.showResult(string: "not logged in")
                } else {
                    self?.showResult(string: "general error")
                }

                return
            }

            guard let safeResult = result else {
                print("no error and no result should not happen")
                return
            }

            print("result_transaction==\(String(describing: safeResult.transactionCode))")

            if safeResult.success {
                print("success")
                var message = "Thank you - \(String(describing: safeResult.transactionCode))"

                if let info = safeResult.additionalInfo,
                    let tipAmount = info["tip_amount"] as? Double, tipAmount > 0,
                    let currencyCode = info["currency"] as? String {
                    message = message.appending("\ntip: \(tipAmount) \(currencyCode)")
                }

                self?.showResult(string: message)
            } else {
                print("cancelled: no error, no success")
                self?.showResult(string: "No charge (cancelled)")
            }
        }

        // after the checkout is initiated we expect a checkout to be in progress
        if !SumUpSDK.checkoutInProgress {
            // something went wrong: checkout was not started
            showResult(string: "failed to start checkout")
        }
    }
}
