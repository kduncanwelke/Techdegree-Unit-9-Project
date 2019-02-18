//
//  ReminderTableViewCell.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 2/18/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import UIKit

class ReminderTableViewCell: UITableViewCell {
	
	@IBOutlet weak var reminderTextLabel: UILabel!
	@IBOutlet weak var remindMeTextLabel: UILabel!
	@IBOutlet weak var locationTextLabel: UILabel!
	@IBOutlet weak var pinLabel: UILabel!
	
	
	static let reuseIdentifier = "Cell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
