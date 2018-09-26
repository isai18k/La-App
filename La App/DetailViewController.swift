//
//  DetailViewController.swift
//  La App
//
//  Created by Jorge Isai Garcia Reyes on 20/09/18.
//  Copyright © 2018 Jorge Isai Garcia Reyes. All rights reserved.
//

import UIKit
import Contacts
import MessageUI

class DetailViewController: UIViewController, MFMessageComposeViewControllerDelegate {

    @IBOutlet weak var contactImage: UIImageView!
    
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var email: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var btnImessage: UIButton!
    
    var phoneNumber: String = ""
    
    var contactItem: CNContact? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.lblDescription.isHidden = false
        self.btnImessage.isHidden = false
        self.configureView()
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let oldContact = self.contactItem {
            let store = CNContactStore()
            
            do {
                let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactPhoneNumbersKey, CNContactImageDataKey, CNContactNoteKey, CNContactImageDataAvailableKey] as [Any]
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
                        if !contact.familyName.isEmpty && !contact.givenName.isEmpty{
                            lblNameInitialize.text = String((CNContactFormatter().string(from: contact)?.first)!) + String(contact.familyName.first!)
                        }else{
                            if !contact.givenName.isEmpty{
                                lblNameInitialize.text = String((CNContactFormatter().string(from: contact)?.first)!)
                            }else{
                                lblNameInitialize.text = "*"
                            }
                        }
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
                    self.phoneNumber = self.phone.text ?? ""
                    
                    if contact.isKeyAvailable(CNContactPostalAddressesKey) {
                        if let postalAddress = contact.postalAddresses.first?.value {
                            self.address.text = CNPostalAddressFormatter().string(from: postalAddress)
                        } else {
                            self.address.text = "No Address"
                        }
                    }
                    
                    if contact.isKeyAvailable(CNContactNoteKey) {
                        if (!contact.note.isEmpty) {
                            print(contact.note)
                            if contact.note == "Usa la App"{
                                self.lblDescription.isHidden = true
                                self.btnImessage.isHidden = true
                            }
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func sendSMSText(sender: AnyObject) {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = ""
            controller.recipients = [phoneNumber]
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

