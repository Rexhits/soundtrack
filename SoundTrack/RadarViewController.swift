//
//  RadarViewController.swift
//  SoundTrack
//
//  Created by WangRex on 3/27/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit

class RadarViewController: UIViewController {

    let currentTask = TaskManager.sharedInstance
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LocationManager.sharedInstance.view = radarView
        LocationManager.sharedInstance.myself = myself
        LocationManager.sharedInstance.target = destination
        LocationManager.sharedInstance.distanceLabel = distance
        LocationManager.sharedInstance.drawingRader(currentTask.latitude[currentTask.selectedTask], DestinationLongtitude: currentTask.longitude[currentTask.selectedTask])
        
        self.view.addSubview(radarView)
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet var radarView: UIView!

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBOutlet var myself: UILabel!
    
    @IBOutlet var destination: UILabel!

    @IBOutlet var distance: UILabel!
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
