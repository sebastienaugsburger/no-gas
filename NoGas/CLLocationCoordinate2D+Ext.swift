//
//  CLLocationCoordinate2D+Ext.swift
//  NoGas
//
//  Created by Sebastien Augsburger on 4/19/25.
//

import Foundation
import MapKit

struct EquatableCoordinate: Equatable {
    let coord: CLLocationCoordinate2D
    
    static func ==(lhs: EquatableCoordinate, rhs: EquatableCoordinate) -> Bool {
        lhs.coord.latitude - rhs.coord.latitude < 0.0001 && lhs.coord.longitude - rhs.coord.longitude < 0.0001
    }
}


