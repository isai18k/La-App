//
//  DetailViewController.swift
//  La App
//
//  Created by Jorge Isai Garcia Reyes on 20/09/18.
//  Copyright © 2018 Jorge Isai Garcia Reyes. All rights reserved.
//

import UIKit
import Contacts

class DetailViewController: UIViewController {

    @IBOutlet weak var contactImage: UIImageView!
    
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var phone: UILabel!
    
    var contactItem: CNContact? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    func configureView() {
        // Update the user interface for the detail item.
        // Update the user interface for the detail item.
        if let oldContact = self.contactItem {
            let store = CNContactStore()
            
            do {
                let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactImageDataAvailableKey] as [Any]
                let contact = try store.unifiedContact(withIdentifier: oldContact.identifier, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                
                DispatchQueue.main.async {
                    if contact.imageDataAvailable {
                        if let data = contact.imageData {
                            self.contactImage.image = UIImage(data: data)
                        }
                    }else{
                        let lblNameInitialize = UILabel()
                        lblNameInitialize.frame.size = CGSize(width: 100.0, height: 100.0)
                        lblNameInitialize.textColor = UIColor.white
                        lblNameInitialize.text = String((CNContactFormatter().string(from: contact)?.first)!) + String(contact.familyName.first!)
                        lblNameInitialize.textAlignment = NSTextAlignment.center
                        lblNameInitialize.backgroundColor = UIColor.black
                        lblNameInitialize.layer.cornerRadius = 50.0
                        
                        UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
                        lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
                        self.contactImage.image = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                    }
                    
                    self.fullName.text = CNContactFormatter().string(from: contact)
                    self.title = self.fullName.text
                    
                    self.email.text = contact.emailAddresses.first?.value as String?
                    self.phone.text = contact.phoneNumbers.first?.value.stringValue as String?
                    
                    if contact.isKeyAvailable(CNContactPostalAddressesKey) {
                        if let postalAddress = contact.postalAddresses.first?.value {
                            self.address.text = CNPostalAddressFormatter().string(from: postalAddress)
                        } else {
                            self.address.text = "No Address"
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

