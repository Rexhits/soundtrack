//
//  MotionManager.swift
//  SoundTrack
//
//  Created by WangRex on 3/16/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import CoreMotion

class MotionManager: NSObject {
    
    static let sharedInstance = MotionManager()
    
    let motionManager = CMMotionManager()
    

    
    func startMotion () {
        self.motionManager.accelerometerUpdateInterval = 0.1
        self.motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue()) { (data: CMAccelerometerData?, err: NSError?) -> Void in
            let x = data!.acceleration.x
            let y = data!.acceleration.y
            let z = data!.acceleration.z
            
            let strength = 1.2
            
            if (fabs(x) > strength || fabs(y) > strength || fabs(z) > strength) {
                
                self.playRandomNote()
            }
            
        }
            
            
    }
    
    func stopMotion() {
        self.motionManager.stopAccelerometerUpdates()
    }
    
    func playRandomNote() {
        let note = Int.random(40, upper: 88)
        let vol =  Int.random(30, upper: 110)
        MusicEngine.sharedInstance.piano.playNote(note, velocity: vol, channel: 1)
        delayFunc(10) {
            MusicEngine.sharedInstance.piano.stopNote(note, channel: 1)
        }
    }
    
}

