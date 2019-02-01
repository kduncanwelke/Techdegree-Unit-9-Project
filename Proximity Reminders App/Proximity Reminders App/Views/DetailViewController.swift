//
//  DetailViewController.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 1/31/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController {
    
    @IBOutlet weak var reminderTextField: UITextField!
    
    var detailItem: Reminder?
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            reminderTextField.text = detailItem?.text
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
    }
    
    func saveEntry() {
        let managedContext = CoreDataManager.shared.managedObjectContext
        
        // save new entry if no item was selected from previous view
        guard let selection = detailItem else {
            let newReminder = Reminder(context: managedContext)
            
            newReminder.text = reminderTextField.text
            
            do {
                try managedContext.save()
            } catch {
                print("Failed to save")
            }
            return
        }
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        saveEntry()
        
        if let navController = splitViewController?.viewControllers[0] as? UINavigationController {
            navController.popViewController(animated: true)
        }
    }
    

}

