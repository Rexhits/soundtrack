//
//  BlockUploadViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 3/28/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import PopupDialog
import SwiftyJSON

class BlockUploadViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, MapSearchDelegate, BouncingDelegate {
    
    
    @IBOutlet weak var playControlBar: UIView!
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    var distance: Double = 20
    
    var location: CLLocationCoordinate2D?
    
    var billboards = [BillboardSerializer]()
    
    var searchController:UISearchController!
    
    @IBOutlet weak var myLocationBtn: UIButton!
    
    @IBOutlet weak var searchBtn: UIButton!
    
    
    var searchResultsController: SearchTableViewController!
    
    @IBOutlet weak var searchCurrentRegionBtn: UIButton!
    
    var selectedBillboard = ""
    
    var timer: Timer?
    
    override func viewDidLoad() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.tappedOnMap(_:)))
        self.mapView.addGestureRecognizer(tap)
        mapView.delegate = self
        locationManager.delegate = self
        searchResultsController = SearchTableViewController()
        searchResultsController.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = true
        searchController.searchBar.barStyle = .blackTranslucent
        searchController.searchBar.delegate = searchResultsController
        PlaybackEngine.shared.bouncingDelegate = self
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.addChildViewController(appDelegate.playbackController)
        appDelegate.playbackController.view.frame = self.playControlBar.bounds
        self.playControlBar.addSubview(appDelegate.playbackController.view)
        appDelegate.playbackController.didMove(toParentViewController: self)
        showBillboards()
        if let block = PlaybackEngine.shared.loadedBlock{
            self.title = block.name
        }
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
        searchCurrentRegionBtn.isHidden = true
        mapView.showsUserLocation = true
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
    

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if location == nil {
            location = locations.first?.coordinate
            let region = MKCoordinateRegionMakeWithDistance(location!, distance.milesToMeters(), distance.milesToMeters())
            mapView.setRegion(region, animated: true)
            fetch()
        }
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
    
    
    func showBillboards() {
        removeAnnotaions()
        
        for i in billboards {
            let dropPin = BillboardAnnotation()
            guard i.latitude != nil && i.longitude != nil else {
                return
            }
            let location = CLLocationCoordinate2DMake(i.latitude!, i.longitude!)
            dropPin.coordinate = location
            dropPin.title = "Billboard"
            dropPin.subtitle = i.name
            dropPin.billboard = i
            let circle = MKCircle(center: location, radius: 30)
            mapView.add(circle)
            mapView.addAnnotation(dropPin)
        }
        if let location = location {
            let region = MKCoordinateRegionMakeWithDistance(location, distance.milesToMeters(), distance.milesToMeters())
            mapView.setRegion(region, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation.isKind(of: MKUserLocation.self) {
            return nil
        } else {
            let view = MKPinAnnotationView()
            view.canShowCallout = true
            view.rightCalloutAccessoryView = UIButton(type: .contactAdd)
            return view
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        UIView.transition(with: searchCurrentRegionBtn, duration: 0.4, options: .transitionCrossDissolve, animations: {
            self.searchCurrentRegionBtn.isHidden = true
        }, completion: nil)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        var mess: String?
        
        if let annotation = view.annotation as? BillboardAnnotation {
            mess = annotation.billboard!.name
            selectedBillboard = annotation.billboard!.url!
        }
        
        
        let popup = PopupDialog.init(title: "Pin On This Billboard?", message: mess, image: nil, buttonAlignment: .vertical, transitionStyle: .bounceUp, gestureDismissal: false, completion: nil)
        
        let ok = DefaultButton(title: "Yes") { 
            PlaybackEngine.shared.bounceCurrentBlock()
        }
        let cancel = CancelButton(title: "Cancel", action: nil)
        popup.addButtons([ok, cancel])
        self.present(popup, animated: true, completion: nil)
        
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
    
    func startBoucing() {
        DispatchQueue.main.sync {
            let title = "Bouncing..."
            let popup = PopupDialog.init(title: title, message: "Uploading to server\n", image: nil, buttonAlignment: .horizontal, transitionStyle: .bounceUp, gestureDismissal: false, completion: nil)
            let length = PlaybackEngine.shared.getSequenceLengthInSec() + 3
            
            let progress = UIProgressView(progressViewStyle: .bar)
            progress.tintColor = UIColor.orange
            
            popup.view.addSubview(progress)
            popup.view.layout(progress).horizontally(left: 60, right: 60).center(offsetX: 0, offsetY: 15)
            let cancel = CancelButton(title: "Cancel") {
                PlaybackEngine.shared.stopBouncing()
            }
            popup.addButton(cancel)
            self.present(popup, animated: true, completion: nil)
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (_) in
                progress.progress += 1.0 / (Float(length) * 10)
            })
        }
    }
    
    func BounceFinshed(path: String) {
        if let block = PlaybackEngine.shared.loadedBlock {
            block.uploadToServer(billboard: selectedBillboard, completion: { (mess) in
                self.dismiss(animated: true, completion: nil)
                self.timer?.invalidate()
                let _ = self.navigationController?.popViewController(animated: true)
            })
        }
        
    }
    
    func bounceStoped() {
        timer?.invalidate()
        self.dismiss(animated: true, completion: nil)
    }
}

class BillboardAnnotation: MKPointAnnotation {
    var billboard: BillboardSerializer?
}

class SearchTableViewController: UITableViewController, UISearchBarDelegate, MKLocalSearchCompleterDelegate {

    var searchCompleter: MKLocalSearchCompleter!
    var completerResult = [MKLocalSearchCompletion]()
    var cell: UITableViewCell!
    var delegate: MapSearchDelegate?
    
    override func viewDidLoad() {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = self
    }
    
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return completerResult.count
    }
    
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchCompleter.queryFragment = searchText
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCell(withIdentifier: "searchCell")
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "searchCell")
        }
        cell!.textLabel?.text = completerResult[indexPath.row].title
        cell!.detailTextLabel?.text = completerResult[indexPath.row].subtitle
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = completerResult[indexPath.row]
        let searchRequest = MKLocalSearchRequest(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        search.start { (response, err) in
            if let pm = response?.mapItems.first?.placemark {
                self.delegate?.foundPlaceMark(placeMark: pm)
            }
        }
    }
    
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        completerResult = completer.results
        self.tableView.reloadData()
    }
}

protocol MapSearchDelegate {
    func foundPlaceMark(placeMark: MKPlacemark)
}

struct BillboardSerializer {
    var address1: String?
    var address2: String?
    var info: String?
    var latitude: Double?
    var longitude: Double?
    var name: String?
    var url: String?
    init(json: JSON) {
        name = json["name"].stringValue
        info = json["info"].stringValue
        address1 = json["address1"].stringValue
        address2 = json["address2"].stringValue
        latitude = json["latitude"].doubleValue
        longitude = json["longitude"].doubleValue
        url = json["url"].stringValue
    }
}

