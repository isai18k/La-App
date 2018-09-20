//
//  ViewController.swift
//  La App
//
//  Created by Jorge Isai Garcia Reyes on 19/09/18.
//  Copyright © 2018 Jorge Isai Garcia Reyes. All rights reserved.
//

import UIKit
import ContactsUI

class ViewController: UIViewController, CNContactPickerDelegate {
    @IBOutlet var lblDetails : UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let contactStore = CNContactStore()
        var contacts = [CNContact]()
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName)]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        do {
            try contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                // Array containing all unified contacts from everywhere
                contacts.append(contact)
            }
        }
        catch {
            print("unable to fetch contacts")
        }
    }
    
    @IBAction func click_Contact(_ sender: Any) {
        let cnPicker = CNContactPickerViewController()
        cnPicker.delegate = self
        self.present(cnPicker, animated: true, completion: nil)
    }

    //MARK:- CNContactPickerDelegate Method
    
//    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
//        contacts.forEach { contact in
//            for number in contact.phoneNumbers {
//                let phoneNumber = number.value
//                print("number is = \(phoneNumber)")
//            }
//        }
//    }
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        print("Cancel Contact Picker")
    }
    
    //____________________
    
    @IBAction func btnSelectContac(_ sender: Any){
        let entityType = CNEntityType.contacts
        let authStatus = CNContactStore.authorizationStatus(for: entityType)
        
        if authStatus == CNAuthorizationStatus.notDetermined{
            let contacStore = CNContactStore.init()
            contacStore.requestAccess(for: entityType, completionHandler: { (succes, nil) in
                if succes{
                    self.openContacts()
                }
                else{
                    print("No autorizado")
                }
            })
            
        }else if authStatus == CNAuthorizationStatus.authorized{
            self.openContacts()
        }
    }
    
    func openContacts(){
        let contactPicker = CNContactPickerViewController.init()
        contactPicker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
        contactPicker.delegate = self
        contactPicker.predicateForSelectionOfContact = NSPredicate (value:true)
        contactPicker.predicateForSelectionOfProperty = NSPredicate(value: true)
        self.present(contactPicker, animated: true, completion: nil)
        
    }
    
//    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
//        let fullName = "\(contact.givenName) \(contact.familyName)"
//        self.lblDetails.text = "Name: \(fullName)"
//    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacProperty: CNContactProperty) {
  
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

