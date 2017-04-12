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
import SwiftyJSON
import PopupDialog

class HuntingMapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, MapSearchDelegate {
    @IBOutlet weak var playControlBar: UIView!
    @IBOutlet weak var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var distance: Double = 20
    var billboards = [BillboardSerializer]()
    
    var location: CLLocationCoordinate2D?
    
    var searchController:UISearchController!
    
    @IBOutlet weak var myLocationBtn: UIButton!
    
    @IBOutlet weak var searchBtn: UIButton!
    
    
    
    var searchResultsController: SearchTableViewController!
    
    var selectedBillboard: BillboardSerializer?
    
    @IBOutlet weak var searchCurrentRegionBtn: UIButton!
    
    override func viewDidLoad() {
        //
        mapView.delegate = self
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tappedOnMap(_:)))
        self.mapView.addGestureRecognizer(tap)
        mapView.delegate = self
        searchResultsController = SearchTableViewController()
        searchResultsController.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.barStyle = .blackTranslucent
        searchController.searchBar.delegate = searchResultsController
//        self.mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.removeAnnotaions()
    }
    
    
    func foundPlaceMark(placeMark: MKPlacemark) {
        location = placeMark.coordinate
        let region = MKCoordinateRegionMakeWithDistance(location!, distance.milesToMeters(), distance.milesToMeters())
        mapView.setRegion(region, animated: true)
        fetch()
        searchController.isActive = false
    }
    
    func tappedOnMap(_ sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: mapView)
        if let subview = mapView.hitTest(tapLocation, with: nil) {
            if subview.isKind(of: NSClassFromString("MKNewAnnotationContainerView")!) {
                if self.searchCurrentRegionBtn.isHidden {
                    UIView.transition(with: searchCurrentRegionBtn, duration: 0.4, options: .transitionCrossDissolve, animations: {
                        self.searchCurrentRegionBtn.isHidden = false
                    }, completion: nil)
                } else {
                    UIView.transition(with: searchCurrentRegionBtn, duration: 0.4, options: .transitionCrossDissolve, animations: {
                        self.searchCurrentRegionBtn.isHidden = true
                    }, completion: nil)
                }
            }
        }
        
    }
    
    func getArtistsOnBoard(billboard: BillboardSerializer, completion: @escaping ([ComposerSerializer])->Void) {
        let url = billboard.url! + "artists/"
        
        ServerCommunicator.shared.get(url: url, body: nil) { (response, err, errCode) in
            guard response != nil else {return}
            let artists = JSON(response!)
            let instances = artists.map{ComposerSerializer(json: $0.1)}
            completion(instances)
        }
    }
    
    override func viewDidLayoutSubviews() {
        let radius = self.searchBtn.bounds.size.height / 2.0
        searchBtn.layer.cornerRadius = radius
        myLocationBtn.layer.cornerRadius = radius
        searchBtn.layer.masksToBounds = true
        myLocationBtn.layer.masksToBounds = true
        searchBtn.backgroundColor = UIColor.orange.withAlphaComponent(0.6)
        myLocationBtn.backgroundColor = UIColor.orange.withAlphaComponent(0.6)
    }
    
    @IBAction func searchCurrentRegion(_ sender: UIButton) {
        location = mapView.region.center
        fetch()
        UIView.transition(with: searchCurrentRegionBtn, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.searchCurrentRegionBtn.isHidden = true
        }, completion: nil)
    }
    
    @IBAction func backToMyLocation(_ sender: UIButton) {
        let loc = mapView.userLocation.coordinate
        let region = MKCoordinateRegionMakeWithDistance(loc, distance.milesToMeters(), distance.milesToMeters())
        mapView.setRegion(region, animated: true)
        
    }
    
    @IBAction func showSearchController(_ sender: UIButton) {
        
        present(searchController, animated: true, completion: nil)
    }
    
    func fetch() {
        if let location = location {
            let body = ["latitude": location.latitude.description, "longitude": location.longitude.description, "distance": distance.description]
            Server.post(api: "billboard/lookup", body: body as JSONPackage) { (response, err, errCode) in
                guard err == nil, errCode == nil else {return}
                guard response != nil else {return}
                let res = response! as! [JSONPackage]
                for i in res {
                    let billboard = BillboardSerializer(json: JSON(i))
                    self.billboards.append(billboard)
                }
                self.showBillboards()
            }
        }
    }
    
    @IBAction func showARBillboard() {
        
        self.performSegue(withIdentifier: "gotoBillboard", sender: self)
    }
    
    
    func showBillboards() {
        removeAnnotaions()
       
        for i in billboards {
            let dropPin = BillboardAnnotation()
            dropPin.billboard = i
            guard i.longitude != nil && i.latitude != nil else {
                return
            }
            let location = CLLocationCoordinate2DMake(i.latitude!, i.longitude!)
            dropPin.coordinate = location
            dropPin.title = i.name
            dropPin.subtitle = i.info
            let circle = MKCircle(center: location, radius: 30)
            mapView.add(circle)
            mapView.addAnnotation(dropPin)
        }
        let myLocation = location!
        let region = MKCoordinateRegionMakeWithDistance(myLocation, distance.milesToMeters(), distance.milesToMeters())
        mapView.setRegion(region, animated: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.addChildViewController(appDelegate.playbackController)
        appDelegate.playbackController.view.frame = self.playControlBar.bounds
        self.playControlBar.addSubview(appDelegate.playbackController.view)
        appDelegate.playbackController.didMove(toParentViewController: self)
        mapView.showsUserLocation = true
        fetch()
    }
    
    func removeAnnotaions() {
        guard mapView.annotations.count > 1 else {
            return
        }
        for i in mapView.annotations {
            guard mapView.view(for: i) != nil else {
                return
            }
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
                let btn = UIButton(type: .custom)
                
                btn.imageView?.contentMode = .scaleToFill
                btn.sizeToFit()
                let image = #imageLiteral(resourceName: "BillboardMapIcon").resize(x: btn.frame.size.height, y: btn.frame.size.height).withRenderingMode(.alwaysTemplate)
                btn.setImage(image, for: .normal)
                btn.sizeToFit()
                annotationView?.rightCalloutAccessoryView = btn
            }
            annotationView?.canShowCallout = true
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            
            let imgView = UIImageView(image: #imageLiteral(resourceName: "MapPin").resize(x: 30, y: 30).colorized(color: UIColor.red))
            imgView.center = CGPoint(x: annotationView!.frame.width / 2, y: annotationView!.frame.height / 2)
            let animation = CABasicAnimation(keyPath: "transform.rotation.y")
            animation.fromValue = 0
            animation.toValue = 2 * Double.pi
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
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation as? BillboardAnnotation {
            self.selectedBillboard = annotation.billboard!
            getArtistsOnBoard(billboard: self.selectedBillboard!, completion: { (artists) in
                let popUp = PopupDialog(title: self.selectedBillboard!.name, message: "\(self.selectedBillboard!.address1!)\n\(self.selectedBillboard!.address2!)\n\n\(artists.count) Featured Artists\n\n\n\n")
                let displayArtists = Array(artists.prefix(5)).map{$0.avatar}
                let width = CGFloat(displayArtists.count * 40)
                let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: width, height: 40))
                stackView.axis = .horizontal
                stackView.distribution = .equalSpacing
                stackView.spacing = 0
                for i in displayArtists {
                    if let data = i as Data? {
                        let image = UIImage(data: data)
                        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                        imageView.image = image
                        imageView.layer.cornerRadius = 20
                        imageView.layer.masksToBounds = false
                        imageView.clipsToBounds = true
                        stackView.addArrangedSubview(imageView)
                    }
                }
                popUp.view.addSubview(stackView)
                popUp.view.layout(stackView).size(stackView.bounds.size).center(offsetX: 0, offsetY: 10)
                let appleMapsBtn = DefaultButton(title: "Maps", action: {
                    let coordinates = CLLocationCoordinate2DMake(self.selectedBillboard!.latitude!, self.selectedBillboard!.longitude!)
                    let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = self.selectedBillboard?.name
                    mapItem.openInMaps(launchOptions: nil)
                })
                
                let googleMapsBtn = DefaultButton(title: "GoogleMaps", action: {
                    let googleMaps = URL(string:"comgooglemaps://")!
                    if UIApplication.shared.canOpenURL(googleMaps) {
                        UIApplication.shared.open(googleMaps, options: [:], completionHandler: nil)
                    }
                })
                
                // make button location related
                let billboardBtn = DefaultButton(title: "Looking for billboard?", action: { 
                    self.showARBillboard()
                })
                
                billboardBtn.titleColor = UIColor.orange
                popUp.addButton(billboardBtn)
                popUp.addButtons([appleMapsBtn, googleMapsBtn])
                
                self.present(popUp, animated: true, completion: nil)
            })
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
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if location == nil {
            location = locations.first?.coordinate
            let region = MKCoordinateRegionMakeWithDistance(location!, distance.milesToMeters(), distance.milesToMeters())
            mapView.setRegion(region, animated: true)
            fetch()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoBillboard" {
            if let vc = segue.destination as? BillboardViewController {
                vc.selectedBillboard = self.selectedBillboard!
            }
        }
    }
}
