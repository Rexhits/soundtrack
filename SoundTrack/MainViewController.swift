//
//  ViewController.swift
//  SoundTrack
//
//  Created by WangRex on 3/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit


class MainViewController: UIViewController {
    
    let musicManager = MusicEngine.sharedInstance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Ask user for location permit
        LocationManager.sharedInstance.askLocationPermission(self)
        
        UserStatus.sharedInstance.motionTracking(self)
        
        
        
        TaskManager.sharedInstance.addNew("Smooth Funk", location: "GaTech", difficulty: "Easy", latitude: [33.775627], longitude: [-84.396296])
    }

    @IBOutlet var start: UIButton!

    @IBAction func pressedStart(sender: UIButton) {
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet var motionSwitch: UISwitch!

    @IBAction func motionSwitchAct(sender: UISwitch) {
        musicManager.loadPatch(["piano"], filename: ["Small Grand Piano"])
        delayFunc(1) { 
            if (self.motionSwitch.on == true) {
                MotionManager.sharedInstance.startMotion()
            } else {
                MotionManager.sharedInstance.stopMotion()
            }
        }
    }
    
    @IBAction func intelligentPlay(sender: UIButton) {
        musicManager.intelligentPlay()
    }

    @IBAction func play(sender: UIButton) {
        musicManager.loadPatch(["piano", "bass", "drum"], filename: ["Small Grand Piano", "Fingerstyle Electric Bass", "Stereo Drum Kit"])
        musicManager.loadMidiFile("test", insts: ["piano", "bass", "drum"])
        musicManager.play()
    }
    
    @IBAction func stop(sender: UIButton) {
        musicManager.stop()
    }
}

