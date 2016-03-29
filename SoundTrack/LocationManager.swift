//
//  Location.swift
//  SoundTrack
//
//  Created by WangRex on 3/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import CoreLocation
import UIKit
import MapKit

// Our Class for handling all location data
class LocationManager: NSObject, CLLocationManagerDelegate  {
    static let sharedInstance = LocationManager()
    //  Create an Global instance of CLLocationManager
    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    
    var distance: Double?
    var heading: Double?
    
    var myLocation: CLLocation?
    
    var DestinationLatitude: Double?
    var DestinationLongitude: Double?
    
    var myself: UILabel?
    var target: UILabel?
    var distanceLabel: UILabel?
    
    var view: UIView?
    
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
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // heading info
        self.heading = newHeading.trueHeading
        let angle = CGFloat(((self.heading!) / 180.0 * M_PI))
        let trans = CGAffineTransformRotate(CGAffineTransformIdentity, angle)
        self.view!.transform = trans
    }
    
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        // location info
        self.myLocation = newLocation
        
        if(self.DestinationLatitude != nil && self.DestinationLongitude != nil) {
            let desLocation = CLLocation(latitude: self.DestinationLatitude!, longitude: self.DestinationLongitude!)
            let desCoordinate = CLLocationCoordinate2D(latitude: self.DestinationLatitude!, longitude: self.DestinationLongitude!)
            self.distance = newLocation.distanceFromLocation(desLocation)
            let myXY = MKMapPointForCoordinate(newLocation.coordinate)
            let desXY = MKMapPointForCoordinate(desCoordinate)
            
            var x = CGFloat((desXY.x - myXY.x) * 1) + (view!.bounds.width / 2)
            var y = CGFloat((desXY.y - myXY.y) * 1) + (view!.bounds.height / 2)
            
            if (x < 0) {
                x = 0
            } else if (x > view!.bounds.width - 20) {
                x = view!.bounds.width - 20
            }
            
            if (y < 0) {
                y = 0
            } else if (y > view!.frame.height - 20) {
                y = view!.bounds.height - 20
            }
            let newFrame = CGRect(x: x, y: y, width: 20, height: 20)
            target!.frame = newFrame
            myself!.frame = CGRect(x: ((view!.bounds.width - 20) / 2), y: ((view!.bounds.height - 20) / 2), width: 20, height: 20)
            let distanceStr = NSString(format: "%.2f", self.distance!)
            self.distanceLabel!.text = "Distance: " + (distanceStr as String) + " M"
            
        }
    }
    
    func drawingRader(DestinationLatitude: Double, DestinationLongtitude: Double) {
        self.DestinationLatitude = DestinationLatitude
        self.DestinationLongitude = DestinationLongtitude
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()

    }
    
    func geocodeRequest(completion: (locality: String, administrativeArea: String) -> Void) {
        locationManager.startUpdatingLocation()
        
        
        var locality: String?
        var administrativeArea: String?
        

        delayFunc(1) {
            if (self.myLocation == nil) {
                return
            } else {
                self.geocoder.reverseGeocodeLocation(self.myLocation!, completionHandler: { (placeMark: [CLPlacemark]?, err: NSError?) in
                    locality = placeMark![0].locality!
                    administrativeArea = placeMark![0].administrativeArea!
                    completion(locality: locality!, administrativeArea: administrativeArea!)
                })
            }

        }
        
    }
    func stopLocationUpdate() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }
    
    func startLocationUpdate() {
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    }
}

