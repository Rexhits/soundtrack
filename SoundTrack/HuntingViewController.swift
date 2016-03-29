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

class HuntingViewController: UITableViewController, MKMapViewDelegate {
    
    @IBOutlet var taskLocationLabel: UILabel!
    
    @IBOutlet var subView: UIView!
    
    @IBOutlet var cells: taskCell!
    
    @IBOutlet var mapView: MKMapView!

    var effectView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
    
    let currentTasks = TaskManager.sharedInstance
    


    @IBOutlet var topBar: UINavigationItem!
    
    var userLocality: String?
    var userAdArea: String?
    
    @IBOutlet var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        LocationManager.sharedInstance.geocodeRequest { (locality, administrativeArea) in
            self.userLocality = locality
            self.userAdArea = administrativeArea
            
            self.searchBar.placeholder = self.userLocality! + " - " + self.userAdArea!
        }
        
        effectView.frame = UIScreen.mainScreen().bounds
        subView.frame = CGRectMake((self.view.frame.width - subView.frame.width) / 2, ((self.view.frame.height - subView.frame.height) / 2) - 30, subView.frame.width, subView.frame.height)
        subView.layer.borderColor = UIColor.blackColor().CGColor
        subView.layer.borderWidth = 1
        
        
        subView.alpha = 0
        effectView.alpha = 0
        
        self.mapView.delegate = self
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tapHandler() {
        self.searchBar.resignFirstResponder()
        self.becomeFirstResponder()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentTasks.name.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("taskCell")! as! taskCell
        cell.nameLabel.text = currentTasks.name[indexPath.row]
        cell.locationLabel.text = currentTasks.location[indexPath.row]
        cell.difficultyLabel.text = currentTasks.difficulty[indexPath.row]
        
        return cell
    }
    


    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //
        print("ok")
        tapHandler()
        addSubView()
        markLocations(indexPath.row)
        TaskManager.sharedInstance.selectedTask = indexPath.row
        self.taskLocationLabel.text = currentTasks.location[indexPath.row]
    }
    
    @IBAction func startHunting(sender: UIButton) {
        
    }
    
    @IBAction func cancelHunting(sender: UIButton) {
        removeSubView()
    }
    
    func addSubView() {
        self.view.addSubview(effectView)
        self.view.addSubview(subView)
        
        UIView.animateWithDuration(0.3) {
            self.effectView.alpha = 0.7
            self.subView.alpha = 1
        }
        subView.becomeFirstResponder()
 

    }
    
    func removeSubView() {
        UIView.animateWithDuration(0.3) {
            self.effectView.alpha = 0
            self.subView.alpha = 0
        }
        subView.resignFirstResponder()

    }
    
    func markLocations(index: Int) {
        var dropPins = [MKPointAnnotation]()
        
        let latitudes = currentTasks.latitude
        let longitudes = currentTasks.longitude
        let theSpan:MKCoordinateSpan = MKCoordinateSpanMake(0.008 , 0.008)
        
        for i in 0 ..< latitudes.count {
            let dropPin = CLLocationCoordinate2DMake(latitudes[i], longitudes[i])
            dropPins.append(MKPointAnnotation())
            dropPins[i].coordinate = dropPin
            mapView.addAnnotation(dropPins[i])
            print(dropPin)
        }
        //just for test
        let theRegion:MKCoordinateRegion = MKCoordinateRegionMake(dropPins[0].coordinate, theSpan)
        mapView.setRegion(theRegion, animated: true)
    }
    
}

class taskCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var difficultyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}


