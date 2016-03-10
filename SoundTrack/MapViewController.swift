//
//  ViewController.swift
//  SoundTrack
//
//  Created by WangRex on 3/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import MapKit

//MapViewController Class inherits from both UIViewController and CLLocationManagerDelegate

class MapViewController: UIViewController, MKMapViewDelegate {
    


    @IBOutlet var mapView: MKMapView!

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mapView.delegate = self
        mapView.userTrackingMode = .Follow
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

