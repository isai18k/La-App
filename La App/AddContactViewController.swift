//
//  AddContactViewController.swift
//  La App
//
//  Created by Jorge Isai Garcia Reyes on 20/09/18.
//  Copyright © 2018 Jorge Isai Garcia Reyes. All rights reserved.
//

import UIKit
import Contacts

class AddContactViewController: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate{
    let imagePicker = UIImagePickerController()
    
    /// Definition of the object or contact to add
    var contact: CNContact {
        get {
            let store = CNContactStore()
            
            let contactToAdd = CNMutableContact()
            contactToAdd.givenName = self.firstName.text ?? ""
            contactToAdd.familyName = self.lastName.text ?? ""
            
            let mobileNumber = CNPhoneNumber(stringValue: (self.mobileNumber.text ?? ""))
            let mobileValue = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: mobileNumber)
            contactToAdd.phoneNumbers = [mobileValue]
  
            let email = CNLabeledValue(label: CNLabelHome, value: self.homeEmail.text! as NSString)
            contactToAdd.emailAddresses = [email]
            
            if let image = self.contactImage.image {
                contactToAdd.imageData = UIImagePNGRepresentation(image)
            }
            
            contactToAdd.note = "Usa la App"
            
            let saveRequest = CNSaveRequest()
            saveRequest.add(contactToAdd, toContainerWithIdentifier: nil)
            
            do {
                try store.execute(saveRequest)
            } catch {
                print(error)
            }
            
            return contactToAdd
        }
    }

    @IBOutlet weak var addImage: UIButton!
    @IBOutlet weak var contactImage: UIImageView!
    
    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var mobileNumber: UITextField!
    @IBOutlet weak var homeEmail: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.hideKeyboardWhenTappedAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /// Send a notification to add to the contact and return to the initial view
    @IBAction func didPressDone(sender: AnyObject) {
        NotificationCenter.default.post(name: NSNotification.Name("addNewContact"), object: nil, userInfo: ["contactToAdd": self.contact])
        self.navigationController?.navigationController?.popViewController(animated: true)
    }
    
    /// Open the photo gallery to select an image
    @IBAction func didPressAddImage(sender: AnyObject) {
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.delegate = self as (UIImagePickerControllerDelegate & UINavigationControllerDelegate)
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    /**
     * Called when 'return' key pressed. return NO to ignore.
     */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

extension UIViewController {
    /// The gesture is added to hide the keyboard, when any area of the view shown was press
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    /// Hide the keyboard
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension AddContactViewController :  UIImagePickerControllerDelegate  {
    /// Function that saved the image, not used
    func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(title: "Saved!", message: "Image saved successfully", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    //MARK: - Done image capture here
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print("image was added")
        self.dismiss(animated: true, completion: nil)
        self.contactImage.image = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
        UIView.animate(withDuration: 0.3) { () -> Void in
            self.contactImage.alpha = 1.0
            self.addImage.alpha = 0.0
        }
    }
    
    // MARK: - Image Picker Delegate
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
//        self.dismiss(animated: true, completion: nil)
//        }
//    }
    
}
