//
//  MixerSubViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/11/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit

class MixerSubviewController: UIViewController {
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var targetChooser: UISegmentedControl!
    var titleStr = "Mixer Control"
    var target = 0
    
    override func viewWillAppear(_ animated: Bool) {
        titleLabel.text = titleStr
        slider.value = PlaybackEngine.shared.selectedTrack.mixer.volume
    }
    override func viewDidLoad() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        slider.addGestureRecognizer(tap)
    }
    func doubleTapped() {
        if target == 0 {
            slider.value = 1
            PlaybackEngine.shared.selectedTrack.mixer.volume = 1
        } else {
            slider.value = 0
            PlaybackEngine.shared.selectedTrack.mixer.pan = 0
        }
    }
    
    @IBAction func targetChanged(_ sender: UISegmentedControl) {
        target = targetChooser.selectedSegmentIndex
        if target == 0 {
            slider.maximumTrackTintColor = UIColor.clear
            slider.value = PlaybackEngine.shared.selectedTrack.mixer.volume
        } else {
            slider.maximumTrackTintColor = UIColor.orange
            slider.value = PlaybackEngine.shared.selectedTrack.mixer.pan
        }
    }
    @IBAction func sliderMoved(_ sender: UISlider) {
        if target == 0 {
            PlaybackEngine.shared.selectedTrack.mixer.volume = slider.value
        } else {
            PlaybackEngine.shared.selectedTrack.mixer.pan = slider.value
        }
    }
}
