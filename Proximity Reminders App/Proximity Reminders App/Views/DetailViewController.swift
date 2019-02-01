//
//  DetailViewController.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 1/31/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var reminderTextField: UITextField!
    
    var detailItem: String? = nil
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            reminderTextField.text = detailItem
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
    }

}

