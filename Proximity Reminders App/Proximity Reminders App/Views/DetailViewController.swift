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

class DetailViewController: UIViewController, CLLocationManagerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UISearchBarDelegate, MapPinDelegate {
    
    @IBOutlet weak var reminderTextField: UITextField!
    @IBOutlet weak var notificationTime: UISegmentedControl!
    @IBOutlet weak var searchContainer: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var detailItem: ReminderList?
    let locationManager = CLLocationManager()
    var searchController = UISearchController(searchResultsController: nil)
    var selectedPin: MKPlacemark?

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
        
        resultsTableController.tableView.delegate = resultsTableController
        resultsTableController.mapView = mapView
        
        // set delegate for map pin
        resultsTableController.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.searchResultsUpdater = resultsTableController
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
     
     guard let location = detailItem?.reminderLocation else { return }
          let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
          print("we made a coordinate")
          let annotation = MKPointAnnotation()
          annotation.coordinate = coordinate
          annotation.title = location.name
     
          mapView.addAnnotation(annotation)
    }
    
    func saveEntry() {
        let managedContext = CoreDataManager.shared.managedObjectContext
        
        // save new entry if no item was selected from previous view
        guard let selection = detailItem else {
          let newReminder = ReminderList(context: managedContext)
          
          let location = ReminderLocale(context: managedContext)
          
          getSelectedLocation(location: location)
          
          newReminder.reminderLocation = location
          getEntry(reminder: newReminder)
            
            do {
                try managedContext.save()
            } catch {
                print("Failed to save")
            }
            return
        }
     
     guard let location = selection.reminderLocation else {
          // location was not set before but one is being added
          
          let location = ReminderLocale(context: managedContext)
          getSelectedLocation(location: location)
          selection.reminderLocation = location
          return
     }
          getSelectedLocation(location: location)
          selection.reminderLocation = location
          getEntry(reminder: selection)
     
        do {
            try managedContext.save()
        } catch {
            print("Failed to save")
        }
    }
    
    func getEntry(reminder: ReminderList) {
        reminder.text = reminderTextField.text
        
        switch notificationTime.selectedSegmentIndex {
        case 0:
            reminder.remindOnEntry = true
            reminder.remindOnExit = false
        case 1:
            reminder.remindOnEntry = false
            reminder.remindOnExit = true
        default:
          reminder.remindOnEntry = false
          reminder.remindOnExit = false
        }
    }
     
     func getSelectedLocation(location: ReminderLocale) {
          guard let selectedLocation = selectedPin else { return }
          location.latitude = selectedLocation.coordinate.latitude
          location.longitude = selectedLocation.coordinate.longitude
          location.name = selectedLocation.title
     }
    
     func getLocation(for pin: MKPlacemark) {
          selectedPin = pin
          mapView.removeAnnotations(mapView.annotations)
     
          let annotation = MKPointAnnotation()
          annotation.coordinate = pin.coordinate
          annotation.title = pin.name
          
          mapView.addAnnotation(annotation)
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
          print("current location: \(lat) \(long)")
            let regionRadius: CLLocationDistance = 1000
           
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
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
