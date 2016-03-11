//
//  ViewController.swift
//  SoundTrack
//
//  Created by WangRex on 3/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit


class MainViewController: UIViewController {
    
    let musicManager = MusicManager.sharedInstance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Ask user for location permit
        Location.sharedInstance.askLocationPermission(self)
        
        UserStatus.sharedInstance.motionTracking(self)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loadMidiFile(sender: UIButton) {
        musicManager.loadPatch(["piano", "bass", "drum"], filename: ["Small Grand Piano", "Fingerstyle Electric Bass", "Stereo Drum Kit"])
        musicManager.loadMidiFile("test", insts: ["piano", "bass", "drum"])
    }

    @IBAction func play(sender: UIButton) {
        try! musicManager.sequencer!.start()
    }
    
    @IBAction func stop(sender: UIButton) {
        musicManager.sequencer!.stop()
        musicManager.sequencer!.prepareToPlay()
    }
}

