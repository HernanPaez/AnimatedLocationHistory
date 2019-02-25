//
//  CLLocationCoordinate2D+Random.swift
//  LocationHistoryAnimated
//
//  Created by Hernan Paez on 24/02/2019.
//  Copyright © 2019 InfinixSoft. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    // create random locations (lat and long coordinates) around user's location
    static func getMockLocationsFor(location: CLLocationCoordinate2D, itemCount: Int) -> [CLLocationCoordinate2D] {
        
        func getBase(number: Double) -> Double {
            return round(number * 1000)/1000
        }
        
        func randomCoordinate() -> Double {
            return Double(arc4random_uniform(140)) * 0.0001
        }
        
        let baseLatitude = getBase(number: location.latitude - 0.01)
        // longitude is a little higher since I am not on equator, you can adjust or make dynamic
        let baseLongitude = getBase(number: location.longitude - 0.01)
        
        var items = [CLLocationCoordinate2D]()
        for _ in 0..<itemCount {
            
            let randomLat = baseLatitude + randomCoordinate()
            let randomLong = baseLongitude + randomCoordinate()
            let location = CLLocationCoordinate2D(latitude: randomLat, longitude: randomLong)
            
            items.append(location)
            
        }
        
        return items
    }
    
}
