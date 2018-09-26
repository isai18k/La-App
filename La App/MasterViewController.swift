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

class MasterViewController: UITableViewController, CNContactPickerDelegate, UISplitViewControllerDelegate {

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
        
        self.splitViewController?.delegate = self
        self.splitViewController?.preferredDisplayMode = .allVisible
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Buscar Contactos sin la App"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        let addExisting = UIBarButtonItem(title: "Ver Agenda", style: .plain, target: self, action:  #selector(showExistingContact))
        self.navigationItem.leftBarButtonItem = addExisting

        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(insertNewObject), name: NSNotification.Name("addNewContact"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateList), name: NSNotification.Name("getContacts"), object: nil)
    }
    
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController) -> Bool {
        // Return true to prevent UIKit from applying its default behavior
        return true
    }
    
    /// function that verifies if there is permission to access the contact list and calls the contact retrieval method.
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
    
    /// function that shows the contacts list
    @objc func showExistingContact() {
        let contactPicker = CNContactPickerViewController.init()
        contactPicker.delegate = self
        self.present(contactPicker, animated: true, completion: nil)
    }
    
    /// Get contacts from the phone book and fill in the fields of contacts to show
    ///
    /// - Parameter store: List with contacts
    func retrieveContactsWithStore(store: CNContactStore) {
        self.objects.removeAll()
        self.contactsSinApp.removeAll()
        
        let contactStore = CNContactStore()
        let keys = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName), CNContactPhoneNumbersKey, CNContactNoteKey, CNContactImageDataKey, CNContactImageDataAvailableKey] as [Any]
        let request = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        do {
            try contactStore.enumerateContacts(with: request) {
                (contact, stop) in
                
                if contact.isKeyAvailable(CNContactNoteKey) {
                    if (!contact.note.isEmpty) {
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
        self.getContacts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /// Insert the new contact to the table
    ///
    /// - Parameter sender: NSNotification
    @objc func insertNewObject(sender: NSNotification) {
        if let contact = sender.userInfo?["contactToAdd"] as? CNContact {
            objects.insert(contact, at: 0)
            let indexPath = IndexPath.init(row: 0, section: 0)
            self.tableView.insertRows(at: [indexPath as IndexPath], with: .automatic)
        }
    }
    
    /// Update the table with Contacts
    ///
    /// - Parameter sender: NSNotification
    @objc func updateList(sender: NSNotification) {
       self.getContacts()
    }

    // MARK: - Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                if isFiltering(){
                    controller.contactItem = filteredContacts[indexPath.section][indexPath.row]
                }else{
                    if indexPath.section == 0{
                        controller.contactItem = objects[indexPath.row]
                    }else {
                        controller.contactItem = contactsWithSections[indexPath.section-1][indexPath.row]
                    }
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

    /// Depending on the section of the table returns the number of contacts to show
    ///
    /// - Parameters:
    ///   - tableView: tableView
    ///   - section: section
    /// - Returns: numberOfRowsInSection
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
    
    /// shows the title of the section
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - section: Int
    /// - Returns: return the title of the section
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = ""
        if !isFiltering() {
            if(section == 0){
                if objects.count == 0{
                    title = ""
                }else{
                     title = "Contactos con la App"
                }
            }else{
                title = sectionTitles[section-1]
            }
        }
       
        return title;
    }
 
    /// Show the contact corresponding to the section of the table
    ///
    /// - Parameters:
    ///   - tableView: UITableView
    ///   - indexPath: cell number
    /// - Returns: return the cell to show
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let formatter = CNContactFormatter()
        
        if isFiltering() {
            let contactFilter : CNContact
            contactFilter = filteredContacts[indexPath.section][indexPath.row]
            cell.textLabel?.text = formatter.string(from: contactFilter)
            cell.detailTextLabel?.text = contactFilter.phoneNumbers.first?.value.stringValue as String?
            self.setImage(contact: contactFilter, cell: cell)
        }else{
            if (indexPath.section == 0) {
                let contact = self.objects[indexPath.row]
  
                cell.textLabel?.text = formatter.string(from: contact)
                cell.detailTextLabel?.text = contact.phoneNumbers.first?.value.stringValue as String?
                self.setImage(contact: contact, cell: cell)
                
            }else{
                let contact = contactsWithSections[indexPath.section-1][indexPath.row]
               
                cell.textLabel?.text = formatter.string(from: contact)
                cell.detailTextLabel?.text = ""
                self.setImage(contact: contact, cell: cell)
            }
            
        }
        return cell
    }
    
    /// Show the contact image or the initials of your name
    ///
    /// - Parameters:
    ///   - contact: Contacto
    ///   - cell: contact cell
    func setImage(contact: CNContact, cell: UITableViewCell){
        if contact.imageDataAvailable {
            if let data = contact.imageData {
                cell.imageView?.image = UIImage(data: data)
                cell.imageView?.frame.size = CGSize(width: 40.0, height: 40.0)
                cell.imageView?.contentMode = .scaleAspectFill
                cell.imageView?.clipsToBounds = true
                cell.imageView?.layer.cornerRadius = 20.0
                
                UIGraphicsBeginImageContext((cell.imageView?.frame.size)!)
                cell.imageView?.layer.render(in: UIGraphicsGetCurrentContext()!)
                cell.imageView?.image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
            }
        }else{
            let lblNameInitialize = UILabel()
            lblNameInitialize.frame.size = CGSize(width: 40.0, height: 40.0)
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
            lblNameInitialize.backgroundColor = UIColor.gray
            lblNameInitialize.clipsToBounds = true
            lblNameInitialize.layer.cornerRadius = 20.0
            
            UIGraphicsBeginImageContext(lblNameInitialize.frame.size)
            lblNameInitialize.layer.render(in: UIGraphicsGetCurrentContext()!)
            cell.imageView?.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
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
    
    /// Show contact info
    ///
    /// - Parameters:
    ///   - picker: CNContactPickerViewController
    ///   - contacProperty: CNContactProperty
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contacProperty: CNContactProperty) {
        print("Show contact info")
    }
    
    // MARK: - Private instance methods
    /// Calidates if the search bar is empty
    ///
    /// - Returns: returns if the search bar is empty
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    /// Filtering contacts that do not use the app
    ///
    /// - Parameters:
    ///   - searchText:
    ///   - scope:
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredContacts = [contactsSinApp.filter({( contact : CNContact) -> Bool in
            let contactoStr = contact.givenName
            return contactoStr.lowercased().contains(searchText.lowercased())
        })]
        
        self.tableView.reloadData()
    }
    
    /// Return true, if the user started looking in the table
    ///
    /// - Returns: True or False
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }

}

extension MasterViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    /// Update the search table
    ///
    /// - Parameter searchController: UISearchController
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
