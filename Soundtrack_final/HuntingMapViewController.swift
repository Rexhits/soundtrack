//
//  HuntingMapViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/8/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class HuntingMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var playControlBar: UIView!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var distance: Double = 20
    var billboards = [Billboard]()
    
    override func viewDidLoad() {
        //
        mapView.delegate = self
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        mapView.showsUserLocation = true
        self.mapView.userTrackingMode = MKUserTrackingMode.follow
    }
    
    
    
    func fetch() {
        let userLocation = mapView.userLocation.coordinate
        let body = ["latitude": userLocation.latitude.description, "longitude": userLocation.longitude.description, "distance": distance.description]
        Server.post(api: "billboard/lookup", body: body as JSONPackage) { (response, err, errCode) in
            guard err == nil, errCode == nil else {return}
            guard response != nil else {return}
            let res = response! as! [JSONPackage]
            for i in res {
                let billboard = Billboard(json: i)
                self.billboards.append(billboard)
            }
            self.showBillboards()
        }
    }
    
    func showBillboards() {
        removeAnnotaions()
       
        for i in billboards {
            let dropPin = MKPointAnnotation()
            let location = CLLocationCoordinate2DMake(i.latitude, i.longitude)
            dropPin.coordinate = location
            dropPin.title = i.name
            dropPin.subtitle = i.info
            let circle = MKCircle(center: location, radius: 30)
            mapView.add(circle)
            mapView.addAnnotation(dropPin)
        }
        let myLocation = mapView.userLocation.coordinate
        let region = MKCoordinateRegionMakeWithDistance(myLocation, distance.milesToMeters(), distance.milesToMeters())
        mapView.setRegion(region, animated: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        showBillboards()
    }
    
    func removeAnnotaions() {
        for i in mapView.annotations {
            for i in mapView.view(for: i)!.subviews {
                i.removeFromSuperview()
            }
        }
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        } else {
            let identifier = "billboardPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if let pin = annotationView {
                pin.annotation = annotation
            }
            else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.annotation = annotation
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            annotationView?.canShowCallout = true
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            let imgView = UIImageView(image: #imageLiteral(resourceName: "MapPin").resize(x: 30, y: 30).colorized(color: UIColor.red))
            imgView.center = CGPoint(x: annotationView!.frame.width / 2, y: annotationView!.frame.height / 2)
            let animation = CABasicAnimation(keyPath: "transform.rotation.y")
            animation.fromValue = 0
            animation.toValue = 2 * M_PI
            animation.duration = 2.0
            animation.repeatCount = HUGE
            imgView.layer.add(animation, forKey: "transform.rotation.y")
            
            annotationView?.layer.shadowColor = UIColor.black.cgColor
            annotationView?.layer.shadowOffset = CGSize(width: 5, height: 5)
            annotationView?.layer.shadowOpacity = 0.5
            annotationView?.layer.shadowRadius = 10.0
            annotationView?.centerOffset = CGPoint(x: 0, y: CGFloat(-annotationView!.frame.size.height / 2))
            annotationView?.addSubview(imgView)
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleView = MKCircleRenderer(overlay: overlay)
        circleView.fillColor = UIColor.orange.withAlphaComponent(0.3)
        return circleView
    }
    

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("selected")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("NotDetermined")
        case .restricted:
            print("Restricted")
        case .denied:
            print("Denied")
        case .authorizedAlways:
            print("AuthorizedAlways")
        case .authorizedWhenInUse:
            print("AuthorizedWhenInUse")
            locationManager.startUpdatingLocation()
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if billboards.isEmpty {
            fetch()
        }
    }
}
