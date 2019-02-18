//
//  MasterViewController.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 1/31/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import CoreLocation

class MasterViewController: UITableViewController, UISplitViewControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var reminders: [ReminderList] = []
	let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
     
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
			
		  // handle split view behavior
          if split.displayMode == .primaryHidden {
               split.preferredDisplayMode = .allVisible
               // prevent collapsing to detail
          } else {
               return
          }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
     
        loadReminders()
    }
     
     func loadReminders() {
          let managedContext = CoreDataManager.shared.managedObjectContext
          let fetchRequest = NSFetchRequest<ReminderList>(entityName: "ReminderList")
          
          do {
               reminders = try managedContext.fetch(fetchRequest)
          } catch let error as NSError {
               print("could not fetch, \(error), \(error.userInfo)")
          }
          
          tableView.reloadData()
     }

    @objc
    func insertNewObject(_ sender: Any) {
        //objects.insert(NSDate(), at: 0)
        //let indexPath = IndexPath(row: 0, section: 0)
        //tableView.insertRows(at: [indexPath], with: .automatic)
		
		if locationManager.monitoredRegions.count == 20 {
			showAlert(title: "Notice", message: "Maximum 20 locations are already been monitored. Further reminders with location monitoring cannot be added.")
		}
		
	 // segue to detail view if in collapsed view, otherwise not
     if let split = splitViewController {
          if split.isCollapsed {
               performSegue(withIdentifier: "showDetail", sender: Any?.self)
          } else {
			// reload detail view to prepare for new item
			if let split = splitViewController {
				let controllers = split.viewControllers
				detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
				detailViewController?.detailItem = nil
				detailViewController?.configureView()
          	}
     		}
    	}
	}

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = reminders[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reminders.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ReminderTableViewCell
		let backgroundView = UIView()
		backgroundView.backgroundColor = UIColor(red:0.01, green:0.45, blue:0.95, alpha:1.0)
		cell.selectedBackgroundView = backgroundView
		
        let object = reminders[indexPath.row]
        cell.reminderTextLabel.text = object.text
		
		if object.remindOnEntry == true {
			cell.remindMeTextLabel.text = "On entering"
			cell.locationTextLabel.text = object.reminderLocation?.address
			cell.pinLabel.isHidden = false
		} else if object.remindOnExit == true {
			cell.remindMeTextLabel.text = "On exiting"
			cell.locationTextLabel.text = object.reminderLocation?.address
			cell.pinLabel.isHidden = false
	   	} else {
		   cell.remindMeTextLabel.text = "No location"
		   cell.pinLabel.isHidden = true
		   cell.locationTextLabel.text = ""
	   	}
		
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
		  let toDelete = reminders[indexPath.row] as ReminderList
			if let latitude = toDelete.reminderLocation?.latitude, let longitude = toDelete.reminderLocation?.longitude, let address = toDelete.reminderLocation?.address {
			
			   // stop monitoring location for deleted item
			   LocationManager.stopMonitoringRegion(latitude: latitude, longitude: longitude, address: address)
				
			   print("stopped monitoring")
			}
			
		  // save core data
          let managedContext = CoreDataManager.shared.managedObjectContext
          managedContext.delete(toDelete)
          
          do {
               try managedContext.save()
          } catch {
               print("Failed to save")
          }
			
		  // lastly remove item from table
		  reminders.remove(at: indexPath.row)
		  tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

