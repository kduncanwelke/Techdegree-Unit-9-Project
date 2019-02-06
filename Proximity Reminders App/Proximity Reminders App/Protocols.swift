//
//  Protocols.swift
//  Proximity Reminders App
//
//  Created by Kate Duncan-Welke on 2/6/19.
//  Copyright © 2019 Kate Duncan-Welke. All rights reserved.
//

import Foundation
import MapKit

protocol MapPinDelegate {
    func getLocation(for: MKAnnotation)
}
