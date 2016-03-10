//
//  Location.swift
//  SoundTrack
//
//  Created by WangRex on 3/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import CoreLocation
import UIKit

// Our Class for handling all location data
class Location: NSObject, CLLocationManagerDelegate, UIAlertViewDelegate {
    static let sharedInstance = Location()
    //  Create an Global instance of CLLocationManager
    let locationManager = CLLocationManager()
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
        
    func askLocationPermission() {
        let authstate = CLLocationManager.authorizationStatus()
        if(authstate != CLAuthorizationStatus.AuthorizedAlways){
            locationManager.requestAlwaysAuthorization()
        }
        if (authstate == CLAuthorizationStatus.Denied) {
            print("denied")
            let alert = UIAlertView()
            alert.addButtonWithTitle("Sure")
            alert.message = "Please turn Location to Always"
            alert.show()
            alert.delegate = self
        }
    }

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
}

