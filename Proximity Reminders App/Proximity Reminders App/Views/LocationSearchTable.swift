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
    
    var delegate: MapPinDelegate?
    
    override func viewDidLoad() {
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "searchCell")
    }

    func parseAddress(selectedItem: MKPlacemark) -> String {
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


extension LocationSearchTable: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = mapView,
            let searchBarText = searchController.searchBar.text else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.resultsList = response.mapItems
            self.tableView.reloadData()
        }
    }

}

extension LocationSearchTable {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        var cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath)
        cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "searchCell")
        
        let selectedItem = resultsList[indexPath.row].placemark
        cell.textLabel?.text = selectedItem.name
        cell.detailTextLabel?.text = parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLocation = resultsList[indexPath.row].placemark
    
        delegate?.getLocation(for: selectedLocation)
        
        self.dismiss(animated: true, completion: nil)
    }
}
