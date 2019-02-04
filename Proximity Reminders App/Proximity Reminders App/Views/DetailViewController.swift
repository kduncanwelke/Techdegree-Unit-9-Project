//
//  DetailViewController.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 1/31/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import MapKit

class DetailViewController: UIViewController, CLLocationManagerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var reminderTextField: UITextField!
    @IBOutlet weak var notificationTime: UISegmentedControl!
    @IBOutlet weak var searchContainer: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var detailItem: Reminder?
    let locationManager = CLLocationManager()
    var searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
        
        // set up search bar
        let resultsTableController = LocationSearchTable()
        
        resultsTableController.tableView.delegate = self
        resultsTableController.mapView = mapView
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        
        searchController.searchBar.placeholder = "Type to search . . ."
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false // The default is true.
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
    }
    
    // assign searchController as navigationItem here, otherwise split view won't display it
    override func viewDidAppear(_ animated: Bool) {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        guard let detail = detailItem else {
            reminderTextField.text = nil
            notificationTime.selectedSegmentIndex = UISegmentedControl.noSegment
            return
        }
        
        reminderTextField.text = detail.text
        if detail.remindOnEntry {
            notificationTime.selectedSegmentIndex = 0
        } else if detail.remindOnExit {
            notificationTime.selectedSegmentIndex = 1
        } else {
            return
        }
        
    }
    
    func saveEntry() {
        let managedContext = CoreDataManager.shared.managedObjectContext
        
        // save new entry if no item was selected from previous view
        guard let selection = detailItem else {
            let newReminder = Reminder(context: managedContext)
            
            getEntry(reminder: newReminder)
            
            do {
                try managedContext.save()
            } catch {
                print("Failed to save")
            }
            return
        }
        
        getEntry(reminder: selection)
        
        do {
            try managedContext.save()
        } catch {
            print("Failed to save")
        }
    }
    
    func getEntry(reminder: Reminder) {
        reminder.text = reminderTextField.text
        
        switch notificationTime.selectedSegmentIndex {
        case 0:
            reminder.remindOnEntry = true
            reminder.remindOnExit = false
        case 1:
            reminder.remindOnEntry = false
            reminder.remindOnExit = true
        default:
            break
        }
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        saveEntry()
        if let masterViewController = splitViewController?.primaryViewController {
            masterViewController.loadReminders()
        }
        
        if let navController = splitViewController?.viewControllers[0] as? UINavigationController {
            navController.popViewController(animated: true)
        }
    }
}


// add location functionality
extension DetailViewController {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lat = locations.last?.coordinate.latitude, let long = locations.last?.coordinate.longitude, let location = locations.last {
            print("\(lat) \(long)")
    
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
        } else {
            print("no coordinates found")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?) -> Void ) {
        // use the last reported location.
        if let lastLocation = self.locationManager.location {
            let geocoder = CLGeocoder()
            
            // look up the location
            geocoder.reverseGeocodeLocation(lastLocation, completionHandler: { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    completionHandler(firstLocation)
                }
                else {
                    // an error occurred during geocoding
                    completionHandler(nil)
                }
            })
        }
        else {
            // no location was available
            completionHandler(nil)
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
}
