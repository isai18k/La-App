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
    
    let collation = UILocalizedIndexedCollation.current()
    var contactsWithSections = [[CNContact]]()
    var sectionTitles = [String]()
    
    var filteredContacts = [[CNContact]]()

    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Buscar Contactos"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
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
        let contactStore = CNContactStore()
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey, CNContactNoteKey] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        do {
            try contactStore.enumerateContacts(with: request) {
                (contact, stop) in
//
                if contact.isKeyAvailable(CNContactNoteKey) {
                    if (!contact.note.isEmpty) {
                        print("aqui hay algo")
                        print(contact.note)
                        if contact.note == "Usa la App"{
                            self.objects.append(contact)
                        }else{
                            self.contactsSinApp.append(contact)
                        }
                    }else{
                        // Array containing all unified contacts from everywhere
                        self.contactsSinApp.append(contact)
                    }
                }// No key available
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            let sortedContactsApp = objects.sorted { $0.givenName < $1.givenName }
            objects = sortedContactsApp

        
            //Create sections of contacts using collation object
            let (arrayContacts, arrayTitles) = collation.partitionObjects(array: self.contactsSinApp, collationStringSelector: #selector(getter: CNContact.givenName))
            self.contactsWithSections = arrayContacts as! [[CNContact]]
            self.sectionTitles = arrayTitles
        }
        catch {
            print(error)
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
                }else {
                    controller.contactItem = contactsWithSections[indexPath.section-1][indexPath.row]
                }
              
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isFiltering() {
            return 1
        }
        return sectionTitles.count + 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredContacts[section].count
        }
        if(section == 0){
            return objects.count
        }else{
            return contactsWithSections[section-1].count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = ""
        if(section == 0){
            title = "Usuarios con la App"
        }else{
            title = sectionTitles[section-1]
        }
        return title;
    }
 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let formatter = CNContactFormatter()
        
        if isFiltering() {
            let contactFilter : CNContact
            contactFilter = filteredContacts[indexPath.section][indexPath.row]
            cell.textLabel?.text = formatter.string(from: contactFilter)
        }else{
            if (indexPath.section == 0) {
                let contact = self.objects[indexPath.row]
  
                cell.textLabel?.text = formatter.string(from: contact)
                cell.detailTextLabel?.text = contact.phoneNumbers.first?.value.stringValue as String?
                
            }else{
                let contact = contactsWithSections[indexPath.section-1][indexPath.row]
               
                cell.textLabel?.text = formatter.string(from: contact)
                cell.detailTextLabel?.text = ""
            }
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
        print("Muestra info del contacto")
    }
    
    // MARK: - Private instance methods
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredContacts = [contactsSinApp.filter({( contact : CNContact) -> Bool in
            let contactoStr = contact.givenName
            return contactoStr.lowercased().contains(searchText.lowercased())
        })]
        
        self.tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

}

extension MasterViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

extension UILocalizedIndexedCollation {
    //func for partition array in sections
    func partitionObjects(array:[AnyObject], collationStringSelector:Selector) -> ([AnyObject], [String]) {
        var unsortedSections = [[AnyObject]]()
        //1. Create a array to hold the data for each section
        for _ in self.sectionTitles {
            unsortedSections.append([]) //appending an empty array
        }
        //2. Put each objects into a section
        for item in array {
            let index:Int = self.section(for: item, collationStringSelector:collationStringSelector)
            unsortedSections[index].append(item)
        }
        //3. sorting the array of each sections
        var sectionTitles = [String]()
        var sections = [AnyObject]()
        for index in 0 ..< unsortedSections.count { if unsortedSections[index].count > 0 {
            sectionTitles.append(self.sectionTitles[index])
            sections.append(self.sortedArray(from: unsortedSections[index], collationStringSelector: collationStringSelector) as AnyObject)
            }
        }
        return (sections, sectionTitles)
    }
}
