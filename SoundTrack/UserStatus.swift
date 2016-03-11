//
//  UserStatus.swift
//  SoundTrack
//
//  Created by WangRex on 3/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import CoreMotion

class UserStatus: NSObject {
    static let sharedInstance = UserStatus()
    
    let activityManager = CMMotionActivityManager()
    let now = NSDate()

    func motionTracking(caller: UIViewController) {
        if (CMMotionActivityManager.isActivityAvailable()) {
            
            activityManager.queryActivityStartingFromDate(now, toDate: now, toQueue: NSOperationQueue.mainQueue(), withHandler: { (activity: [CMMotionActivity]?, error: NSError?) -> Void in
                if (error != nil) {
                    if(error!.code != Int(CMErrorMotionActivityNotAuthorized.rawValue)){
                        print("CMErrorMotionActivityNotAuthorized")
                    }else if(error!.code != Int(CMErrorMotionActivityNotEntitled.rawValue)){
                        print("CMErrorMotionActivityNotEntitled")
                        
                        let alert = UIAlertController(title: "Motion & Fitness Permission", message: "Please turn on Motion & Fitness", preferredStyle: .Alert)
                        let action = UIAlertAction(title: "Sure", style: .Default, handler: { (action: UIAlertAction) -> Void in
                            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                        })
                        alert.addAction(action)
                        caller.presentViewController(alert, animated: true, completion: nil)
                        
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

            
            let alert = UIAlertController(title: "Activity Tracking Error", message: "OOPS, Activity Data Not Avaliable", preferredStyle: .Alert)
            let action = UIAlertAction(title: "Sure", style: .Default, handler: nil)
            alert.addAction(action)
            caller.presentViewController(alert, animated: true, completion: nil)
        }
    }

}