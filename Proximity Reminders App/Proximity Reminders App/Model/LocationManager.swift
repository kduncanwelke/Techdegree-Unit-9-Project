//
//  LocationManager.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 2/9/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import UserNotifications
import CoreData

struct LocationManager {
	// get region to monitor geofence for
	static func getMonitoringRegion(for location: MKPointAnnotation, address: String, notifyOnEntry: Bool, notifyOnExit: Bool) -> CLCircularRegion {
		let coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
		let region = CLCircularRegion(center: coordinate, radius: 50.0, identifier: address)
		region.notifyOnEntry = notifyOnEntry
		region.notifyOnExit = notifyOnExit
		return region
	}
	
	// stop monitoring given geofence
	static func stopMonitoringRegion(latitude: Double, longitude: Double, address: String) {
		let locationManager = CLLocationManager()
		let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
		let selectedRegion = CLCircularRegion(center: coordinate, radius: 50.0, identifier: address)
	
		locationManager.stopMonitoring(for: selectedRegion)
	}
	
	// handle action when geofence is triggered
	static func handleEvent(for region: CLRegion) {
		print("event handled")
		
		let identifier = region.identifier
		
		let managedContext = CoreDataManager.shared.managedObjectContext
		let fetchRequest = NSFetchRequest<ReminderList>(entityName: "ReminderList")
		fetchRequest.predicate = NSPredicate(format: "reminderLocation.address == %@", identifier)
		
		// load particular reminder for triggered geofence using predicate
		var reminder: [ReminderList] = []
		do {
			reminder = try managedContext.fetch(fetchRequest)
		} catch let error as NSError {
			print("could not fetch, \(error), \(error.userInfo)")
		}
		
		guard let retrievedReminder = reminder.first else { return }
		let reminderText = retrievedReminder.text
		
		let notificationCenter = UNUserNotificationCenter.current()
		
		let notificationContent = UNMutableNotificationContent()
		notificationContent.title = "Reminder Activated"
		notificationContent.body = reminderText ?? "You have entered a reminder-based region."
		notificationContent.sound = UNNotificationSound.default
		
		let trigger = UNLocationNotificationTrigger(region: region, repeats: false)

		let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
		
		
		notificationCenter.add(request) { (error) in
			if error != nil {
				print("Error adding notification with identifier: \(identifier)")
			}
		}
	}
	
	static func parseAddress(selectedItem: MKPlacemark) -> String {
		// put a space between "4" and "Melrose Place"
		let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
		// put a comma between street and city/state
		let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
		// put a space between "Washington" and "DC"
		let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
		let addressLine = String(
			format:"%@%@%@%@%@%@%@",
			// street number
			selectedItem.subThoroughfare ?? "",
			firstSpace,
			// street name
			selectedItem.thoroughfare ?? "",
			comma,
			// city
			selectedItem.locality ?? "",
			secondSpace,
			// state
			selectedItem.administrativeArea ?? ""
		)
		return addressLine
	}
}
