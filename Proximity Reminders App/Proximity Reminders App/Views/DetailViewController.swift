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
	var pinAddress: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestLocation()
		locationManager.startUpdatingLocation()
        
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
		
		// perform check for location services access, as this is the first point of use
		if CLLocationManager.locationServicesEnabled() {
			switch CLLocationManager.authorizationStatus() {
			case .notDetermined, .restricted, .denied:
				showAlert(title: "Notice", message: "Access to location services has not been granted. This may result in undesired behavior.")
			case .authorizedAlways, .authorizedWhenInUse:
				print("Access")
			}
		} else {
			showAlert(title: "Notice", message: "Location service is not available - all features of this app may not be available.")
		}
    }
    
    // assign searchController as navigationItem here, otherwise split view won't display it
    override func viewDidAppear(_ animated: Bool) {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    func configureView() {
        // update the user interface with the selected detail item if there was one
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
		
		// if there is an associated location, load it and its overlay
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
			
			var location: ReminderLocale?
           location = ReminderLocale(context: managedContext)
          
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
		
		// otherwise resave existing item
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
	
	// get info entered by user
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
	
	// acquire location based on placed map pin
     func getSelectedLocation(location: ReminderLocale?) {
		guard let selectedLocation = selectedPin, let location = location, let annotation = mapView.annotations.first?.subtitle else { return }
          location.latitude = selectedLocation.coordinate.latitude
          location.longitude = selectedLocation.coordinate.longitude
          location.name = selectedLocation.name
		  location.address = annotation
     }
	
	// add map annotation and region for location monitoring based on pin
     func getLocation(for pin: MKPlacemark) {
          selectedPin = pin
          mapView.removeAnnotations(mapView.annotations)
		  mapView.removeOverlays(mapView.overlays)
          let annotation = MKPointAnnotation()
          annotation.coordinate = pin.coordinate
          annotation.title = pin.name
		  annotation.subtitle = LocationManager.parseAddress(selectedItem: pin)
			pinAddress = annotation.subtitle
		
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
		if locationManager.monitoredRegions.count == 20 && selectedPin != nil {
			showAlert(title: "Unable to save", message: "The maximum of 20 monitored locations has been met - please delete or modify an existing reminder.")
		} else if reminderTextField.text == "" {
			showAlert(title: "Missing information", message: "Please enter some text for your reminder")
		} else {
			// start monitoring location if one was added
			if let pin = selectedPin {
				 let annotation = MKPointAnnotation()
				 annotation.coordinate = pin.coordinate
				
				 var remindOnEntry = false
				 var remindOnExit = false
				
				 switch notificationTime.selectedSegmentIndex {
				 case 0:
					 remindOnEntry = true
					 remindOnExit = false
				 case 1:
					 remindOnEntry = false
					 remindOnExit = true
				 default:
					 remindOnEntry = false
					 remindOnExit = false
				 }
				
				 guard let address = pinAddress else { return }
				
				 let geofenceArea = LocationManager.getMonitoringRegion(for: annotation, address: address, notifyOnEntry: remindOnEntry, notifyOnExit: remindOnExit)
				
				 if locationManager.monitoredRegions.contains(geofenceArea) {
					 showAlert(title: "Pre-existing Geofence", message: "The area you have selected is already being monitored - please select a different region.")
					 print("area already in use")
				 } else {
					
				 locationManager.startMonitoring(for: geofenceArea)
				 print("\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)")
				 print("started monitoring")
					}
			}
			
			// save entry and either pop back to view or reload table data depending on split view display
			 saveEntry()
			
			 if let masterViewController = splitViewController?.primaryViewController {
				 masterViewController.loadReminders()
				detailItem = nil
				self.configureView()
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
		// if a pin has been placed, don't proceed to detect and recenter on current location
		if selectedPin != nil {
			return
		} else {
		// if no item with an associated location is being shown, display current location
		if detailItem?.reminderLocation?.address == nil {
			 if let lat = locations.last?.coordinate.latitude, let long = locations.last?.coordinate.longitude, let location = locations.last {
			   print("current location: \(lat) \(long)")
				 let regionRadius: CLLocationDistance = 1000
				
				 let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
				 mapView.setRegion(region, animated: true)
			 } else {
				 print("no coordinates found")
			 }
		} else {
			return
		}
    }
	}
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?) -> Void ) {
        // use the last reported location
        if let lastLocation = self.locationManager.location {
            let geocoder = CLGeocoder()
            
            // look up the location name
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
	
	// limit text field characters to 50
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		let currentText = textField.text ?? ""
		guard let stringRange = Range(range, in: currentText) else { return false }
		
		let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
		
		return updatedText.count <= 50
	}
}
