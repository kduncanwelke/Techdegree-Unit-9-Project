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
}

// update results for search table
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
        cell.detailTextLabel?.text = LocationManager.parseAddress(selectedItem: selectedItem)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLocation = resultsList[indexPath.row].placemark
	
		// pass selected location via delegate
        delegate?.getLocation(for: selectedLocation)
        
        self.dismiss(animated: true, completion: nil)
    }
}
