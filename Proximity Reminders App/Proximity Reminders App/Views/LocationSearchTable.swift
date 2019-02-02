//
//  LocationSearchTable.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 2/1/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import UIKit

class LocationSearchTable: UITableViewController {
    
    override func viewDidLoad() {
        self.definesPresentationContext = true
    }
}


extension LocationSearchTable : UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
    }
}
