//
//  UserStatus.swift
//  SoundTrack
//
//  Created by WangRex on 3/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import CoreMotion

class UserStatus: NSObject, UIAlertViewDelegate {
    static let sharedInstance = UserStatus()
    
    let activityManager = CMMotionActivityManager()
    let now = NSDate()

    func motionTracking() {
        if (CMMotionActivityManager.isActivityAvailable()) {
            
            activityManager.queryActivityStartingFromDate(now, toDate: now, toQueue: NSOperationQueue.mainQueue(), withHandler: { (activity: [CMMotionActivity]?, error: NSError?) -> Void in
                if (error != nil) {
                    if(error!.code != Int(CMErrorMotionActivityNotAuthorized.rawValue)){
                        print("CMErrorMotionActivityNotAuthorized")
                    }else if(error!.code != Int(CMErrorMotionActivityNotEntitled.rawValue)){
                        print("CMErrorMotionActivityNotEntitled")
                        let alert = UIAlertView()
                        alert.addButtonWithTitle("Sure")
                        alert.message = "Please turn on Motion & Fitness"
                        alert.show()
                        alert.delegate = self
                    }else if(error!.code != Int(CMErrorMotionActivityNotAvailable.rawValue)){
                        print("CMErrorMotionActivityNotAvailable")
                    }
                }
            })
            
            activityManager.startActivityUpdatesToQueue(NSOperationQueue()) { (activity: CMMotionActivity?) -> Void in
                if (activity!.stationary) {
                    print("User is stationary")
                    
                }
                
                if (activity!.walking) {
                    print("User is walking")


                }
                
                if (activity!.running) {
                    print("User is running")

                }
                
                if (activity!.automotive) {
                    print("User is audiomotive")
                    
                }
                
                if (activity!.cycling) {
                    print("User is cycling")
                    
                }
                
                if (activity!.unknown) {
                    print("User Status Unknow")
                }
            }
        } else {
            let alert = UIAlertView()
            alert.addButtonWithTitle("OK")
            alert.message = "OOPS, Activity Data Not Avaliable"
            alert.show()
        }
    }
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
    }
}