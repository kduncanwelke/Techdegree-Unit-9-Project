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

// add reusable alert functionality
extension UIViewController {
	func showAlert(title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}
}
