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
	static func getMonitoringRegion(for location: MKPointAnnotation, notifyOnEntry: Bool, notifyOnExit: Bool) -> CLCircularRegion {
		let coordinate = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
		let region = CLCircularRegion(center: coordinate, radius: 50.0, identifier: location.title ?? "new location")
		region.notifyOnEntry = notifyOnEntry
		region.notifyOnExit = notifyOnExit
		return region
	}
	
	static func stopMonitoringRegion(latitude: Double, longitude: Double, title: String) {
		let locationManager = CLLocationManager()
		let coordinate = CLLocationCoordinate2DMake(latitude, longitude)
		let selectedRegion = CLCircularRegion(center: coordinate, radius: 50.0, identifier: title)
	
		locationManager.stopMonitoring(for: selectedRegion)
	}
	
	static func handleEvent(for region: CLRegion) {
		print("event handled")
		
		let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
		let identifier = region.identifier
		
		let text = identifier
		let managedContext = CoreDataManager.shared.managedObjectContext
		let fetchRequest = NSFetchRequest<ReminderList>(entityName: "ReminderList")
		fetchRequest.predicate = NSPredicate(format: "text == %@", text)
		
		var reminder: ReminderList?
		do {
			reminder = try managedContext.fetch(fetchRequest).first
		} catch let error as NSError {
			print("could not fetch, \(error), \(error.userInfo)")
		}
		
		guard let notificationReminder = reminder else { return }
		
		let notificationContent = UNMutableNotificationContent()
		notificationContent.title = "Reminder Activated"
		notificationContent.body = "\(String(describing: notificationReminder.text))"
		notificationContent.sound = UNNotificationSound.default
		
		print(notificationReminder.text)
		
		let request = UNNotificationRequest(identifier: identifier, content: notificationContent, trigger: trigger)
		
		let notificationCenter = UNUserNotificationCenter.current()
		notificationCenter.add(request, withCompletionHandler: { (error) in
			if error != nil {
				print("Error adding notification with identifier: \(identifier)")
			}
		})
	}
}
