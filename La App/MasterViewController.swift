//
//  MasterViewController.swift
//  La App
//
//  Created by Jorge Isai Garcia Reyes on 20/09/18.
//  Copyright © 2018 Jorge Isai Garcia Reyes. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class MasterViewController: UITableViewController, CNContactPickerDelegate {

    var detailViewController: DetailViewController? = nil
    var objects = [CNContact]()
    var contactsSinApp = [CNContact]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let addExisting = UIBarButtonItem(title: "Add Existing", style: .plain, target: self, action:  #selector(addExistingContact))
        self.navigationItem.leftBarButtonItem = addExisting

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(insertNewObject), name: NSNotification.Name("addNewContact"), object: nil)
        self.getContacts()
    }
    
    func getContacts() {
        let store = CNContactStore()
        
        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            
            store.requestAccess(for: CNEntityType.contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    self.retrieveContactsWithStore(store: store)
                }
            })
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            self.retrieveContactsWithStore(store: store)
        }
    }
    
    @objc func addExistingContact() {
        let contactPicker = CNContactPickerViewController.init()
        contactPicker.delegate = self
        self.present(contactPicker, animated: true, completion: nil)
    }
    
    func retrieveContactsWithStore(store: CNContactStore) {
        let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey, CNContactNoteKey] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keysToFetch as! [CNKeyDescriptor])
        var cnContacts = [CNContact]()
        do {
            try store.enumerateContacts(with: request){
                (contact, cursor) -> Void in
                if (!contact.note.isEmpty) {
                     NSLog("aqui hay algo")
                }
                
                if contact.isKeyAvailable(CNContactNoteKey) {
                    if let contactNotetext = contact.note as String {
                        print(contactNotetext) // Print the image set on the contact
                    }
                } else {
                    // No Image available
                    
                }
                if (!contact.emailAddresses.isEmpty) {
                }
                cnContacts.append(contact)
                self.objects = cnContacts
            }
        } catch let error {
            NSLog("Fetch contact error: \(error)")
        }
        do {
            let groups = try store.groups(matching: nil)
//            let predicate = CNContact.predicateForContactsInGroup(withIdentifier: groups[0].identifier)
            let predicate = CNContact.predicateForContacts(matchingName: "John")
            let keysToFetch = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey] as [Any]
            
            let contacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
            self.objects = contacts
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } catch {
            print(error)
        }
        
        let contactStore = CNContactStore()
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        do {
            try contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                // Array containing all unified contacts from everywhere
                self.contactsSinApp.append(contact)
            }
        }
        catch {
            print("unable to fetch contacts")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func insertNewObject(sender: NSNotification) {
        if let contact = sender.userInfo?["contactToAdd"] as? CNContact {
            objects.insert(contact, at: 0)
            let indexPath = IndexPath.init(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath as IndexPath], with: .automatic)
        }
    }

    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                
                if indexPath.section == 0{
                    controller.contactItem = objects[indexPath.row]
                }else if indexPath.section == 1{
                    controller.contactItem = contactsSinApp[indexPath.row]
                }
              
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        if(objects.count > 0){
            return 2
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == 0){
            return objects.count
        }else if(section == 1){
            return contactsSinApp.count
        }else{
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
       
        var title = ""
        if(section == 0){
            title = "Usuarios con la App"}
        if(section == 1){
            title = "Lista de Contactos"}
        return title;
    }
 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if (indexPath.section == 0) {
            let contact = self.objects[indexPath.row]
            let formatter = CNContactFormatter()
            
            cell.textLabel?.text = formatter.string(from: contact)
            cell.detailTextLabel?.text = contact.phoneNumbers.first?.value.stringValue as String?
            
        }else if(indexPath.section == 1){
            let contact = self.contactsSinApp[indexPath.row]
            let formatter = CNContactFormatter()
            
            cell.textLabel?.text = formatter.string(from: contact)
            cell.detailTextLabel?.text = ""
        }
      
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    //MARK: - Contack Picker
//    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
////         NotificationCenter.default.post(name: NSNotification.Name("addNewContact"), object: nil, userInfo: ["contactToAdd": contact])
//
//    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacProperty: CNContactProperty) {
        
    }

}

