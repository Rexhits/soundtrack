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
class Location: NSObject, CLLocationManagerDelegate  {
    static let sharedInstance = Location()
    //  Create an Global instance of CLLocationManager
    let locationManager = CLLocationManager()
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
        
    func askLocationPermission(caller: UIViewController) {
        let authstate = CLLocationManager.authorizationStatus()
        if(authstate != CLAuthorizationStatus.AuthorizedAlways){
            locationManager.requestAlwaysAuthorization()
        }
        if (authstate == CLAuthorizationStatus.Denied) {
            print("denied")
            let alert = UIAlertController(title: "Location Permission", message: "Please Please turn Location to Always", preferredStyle: .Alert)
            let action = UIAlertAction(title: "Sure", style: .Default, handler: { (action: UIAlertAction) -> Void in
                 UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            })
            alert.addAction(action)
            caller.presentViewController(alert, animated: true, completion: nil)
        }
    }
    

}

