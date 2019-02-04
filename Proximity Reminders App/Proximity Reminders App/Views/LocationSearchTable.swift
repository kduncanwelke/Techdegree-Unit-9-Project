//
//  LocationSearchTable.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 2/1/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class LocationSearchTable: UITableViewController {
    
    var resultsList: [MKMapItem] = [MKMapItem]()
    var mapView: MKMapView? = nil
    
    override func viewDidLoad() {
        self.definesPresentationContext = true
    }

}


extension LocationSearchTable: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        print("we got here")
        guard let mapView = mapView,
            let searchBarText = searchController.searchBar.text else { return }
        mapView.removeAnnotations(mapView.annotations)
        
        resultsList.removeAll()
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start(completionHandler: {(response, error) in
            
            if let results = response {
                
                if let err = error {
                    print("Error occurred in search: \(err.localizedDescription)")
                } else if results.mapItems.count == 0 {
                    print("No matches found")
                } else {
                    print("Matches found")
                    
                    for item in results.mapItems {
                        print("Name = \(item.name ?? "No match")")
                        print("Phone = \(item.phoneNumber ?? "No Match")")
                        
                        self.resultsList.append(item as MKMapItem)
                        print("Matching items = \(self.resultsList.count)")
                        
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = item.placemark.coordinate
                        annotation.title = item.name
                        mapView.addAnnotation(annotation)
                    }
                }
            }
        })
       self.tableView.reloadData()
    }

}

extension LocationSearchTable {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell")!
        let selectedItem = resultsList[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = ""
        return cell
    }
}
