//
//  ViewController.swift
//  ECBTDemo
//
//  Created by Orcun on 13/04/2018.
//  Copyright © 2018 Orcun. All rights reserved.
//

import UIKit
import Braintree


class ViewController: UIViewController {

// Declare BTAPIClient
var braintreeClient: BTAPIClient!

// Spinner
@IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        spinner.hidesWhenStopped = true
        // Client token retrieval
        let clientTokenURL = NSURL(string: "http://orcodevbox.co.uk/max/token.php")!
        let clientTokenRequest = NSMutableURLRequest(url: clientTokenURL as URL)
        clientTokenRequest.setValue("text/plain", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: clientTokenRequest as URLRequest) { (data, response, error) -> Void in
            // TODO: Handle errors
            let clientToken = String(data: data!, encoding: String.Encoding.utf8)
            
            print(clientToken!)
            
            // Initialize braintreeClient
            self.braintreeClient = BTAPIClient(authorization: clientToken!)

            }.resume()
        
    }
    
    @IBAction func launchPayPal(_ sender: Any) {
        
        let payPalDriver = BTPayPalDriver(apiClient: braintreeClient)
        payPalDriver.viewControllerPresentingDelegate = self as? BTViewControllerPresentingDelegate
        payPalDriver.appSwitchDelegate = self as? BTAppSwitchDelegate // Optional
        
        // Specify the transaction amount here. "2.32" is used in this example.
        let request = BTPayPalRequest(amount: "2.32")
        request.currencyCode = "USD" // Optional; see BTPayPalRequest.h for more options
        
        payPalDriver.requestOneTimePayment(request) { (tokenizedPayPalAccount, error) in
            if let tokenizedPayPalAccount = tokenizedPayPalAccount {
                print("Got a nonce: \(tokenizedPayPalAccount.nonce)")
                
                
                // Access additional information
                let email = tokenizedPayPalAccount.email
                let firstName = tokenizedPayPalAccount.firstName
                let lastName = tokenizedPayPalAccount.lastName
                let phone = tokenizedPayPalAccount.phone
                
                // See BTPostalAddress.h for details
                let billingAddress = tokenizedPayPalAccount.billingAddress
                let shippingAddress = tokenizedPayPalAccount.shippingAddress
                
                // Send the nonce to the server
                self.postNonceToServer(paymentMethodNonce: tokenizedPayPalAccount.nonce)
                
            } else if let error = error {
                // Handle error here...
            } else {
                // Buyer canceled payment approval
            }
        }
    }
    
    // Function for sending the nonce to server
    func postNonceToServer(paymentMethodNonce : String) {
        
        spinner.startAnimating()
        let price = 10
        let paymentURL = NSURL(string: "http://orcodevbox.co.uk/max/transaction.php")!
        let request = NSMutableURLRequest(url: paymentURL as URL)
        request.httpBody = "amount=\(Double(price))&payment_method_nonce=\(paymentMethodNonce)".data(using: String.Encoding.utf8);
        request.httpMethod = "POST"
        
        
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            // TODO: Handle success or failure
            let responseData = String(data: data!, encoding: String.Encoding.utf8)
            
            
            // Log the response in console
            print(responseData!);
            
            // Display the result in an alert view
            DispatchQueue.main.async(execute: {
                self.spinner.stopAnimating()
                let alertResponse = UIAlertController(title: "Result", message: "\(String(describing: responseData))", preferredStyle: UIAlertControllerStyle.alert)
                
                // add an action to the alert (button)
                alertResponse.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                
                // show the alert
                self.present(alertResponse, animated: true, completion: nil)
                
            })
            
            }.resume()
        
    }
    
    // MARK: - BTViewControllerPresentingDelegate
    
    func paymentDriver(_ driver: Any, requestsPresentationOf viewController: UIViewController) {
        present(viewController, animated: true, completion: nil)
    }
    
    func paymentDriver(_ driver: Any, requestsDismissalOf viewController: UIViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - BTAppSwitchDelegate
    func appSwitcher(_ appSwitcher: Any, didPerformSwitchTo target: BTAppSwitchTarget) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

