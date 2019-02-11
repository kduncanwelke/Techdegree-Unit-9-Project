//
//  MasterViewController.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 1/31/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, UISplitViewControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var reminders: [ReminderList] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
     
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
          
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
     
     if let split = splitViewController {
          if split.isCollapsed {
               performSegue(withIdentifier: "showDetail", sender: Any?.self)
          } else {
               //something
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = reminders[indexPath.row]
        cell.textLabel!.text = object.text
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
			let toDelete = reminders[indexPath.row] as ReminderList
			guard let latitude = toDelete.reminderLocation?.latitude, let longitude = toDelete.reminderLocation?.longitude, let title = toDelete.text else { return }
			
			LocationManager.stopMonitoringRegion(latitude: latitude, longitude: longitude, title: title)
			print("stopped monitoring")
			
          let managedContext = CoreDataManager.shared.managedObjectContext
          managedContext.delete(toDelete)
          
          do {
               try managedContext.save()
          } catch {
               print("Failed to save")
          }
			
            reminders.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }


}

