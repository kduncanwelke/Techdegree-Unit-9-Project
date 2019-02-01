//
//  Extensions.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 2/1/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import UIKit

extension UISplitViewController {
    var primaryViewController: MasterViewController? {
        let navController = self.viewControllers.first as? UINavigationController
        return navController?.topViewController as? MasterViewController
    }
}
