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

class DetailViewController: UIViewController, CLLocationManagerDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDelegate, UISearchBarDelegate, MapPinDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var reminderTextField: UITextField!
    @IBOutlet weak var notificationTime: UISegmentedControl!
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
		
		mapView.delegate = self
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
          let annotation = MKPointAnnotation()
          annotation.coordinate = coordinate
          annotation.title = location.name
		
		let circle = MKCircle(center: annotation.coordinate, radius: 50)
		mapView.addOverlay(circle)
     
          mapView.addAnnotation(annotation)
     
     let regionRadius: CLLocationDistance = 500
     let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
     mapView.setRegion(region, animated: true)
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
          location.name = selectedLocation.name
     }
    
     func getLocation(for pin: MKPlacemark) {
          selectedPin = pin
          mapView.removeAnnotations(mapView.annotations)
		
          let annotation = MKPointAnnotation()
          annotation.coordinate = pin.coordinate
          annotation.title = pin.name
		
		let regionRadius: CLLocationDistance = 500
		
		let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
			mapView.setRegion(region, animated: true)
			let circle = MKCircle(center: annotation.coordinate, radius: 50)
		
			mapView.addAnnotation(annotation)
			mapView.addOverlay(circle)
    }

	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
			circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.5)
			circleRenderer.strokeColor = UIColor.white
			circleRenderer.lineWidth = 1.0
			return circleRenderer
	}
    
    @IBAction func saveTapped(_ sender: Any) {
		if reminderTextField.text == "" {
			showAlert(title: "Missing information", message: "Please enter some text for your reminder")
		} else {
			 saveEntry()
			 if let masterViewController = splitViewController?.primaryViewController {
				 masterViewController.loadReminders()
			 }
			
			 if let navController = splitViewController?.viewControllers[0] as? UINavigationController {
				 navController.popViewController(animated: true)
			 }
		 }
	}
}


// add location functionality
extension DetailViewController {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		// if no item and associated location are being shown, display current location
		if detailItem == nil {
			 if let lat = locations.last?.coordinate.latitude, let long = locations.last?.coordinate.longitude, let location = locations.last {
			   print("current location: \(lat) \(long)")
				 let regionRadius: CLLocationDistance = 1000
				
				 let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
				 mapView.setRegion(region, animated: true)
			 } else {
				 print("no coordinates found")
			 }
		} else {
			return // if
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
