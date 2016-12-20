//
//  PlayToolBarView.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/12/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import AVFoundation

class PlayControlBarView: UIViewController, PlaybackEngineDelegate {
    
    @IBOutlet weak var playStopBtn: UIButton!
    
    @IBOutlet weak var loopBtn: UIButton!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    var playtimeDelegate: PlayControlBarDelegate?
    
    override func viewDidLoad() {
        PlaybackEngine.shared.delegate = self
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        playStopBtn.isUserInteractionEnabled = false
        playStopBtn.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        playStopBtn.setImage(#imageLiteral(resourceName: "Pause"), for: .selected)
        playStopBtn.tintColor = UIColor.orange
        playStopBtn.layer.borderColor = UIColor.orange.cgColor
        playStopBtn.backgroundColor = UIColor.clear
        playStopBtn.layer.borderWidth = 2.0
        playStopBtn.layer.cornerRadius = playStopBtn.bounds.size.width / 2
        playStopBtn.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 2.0)
        playStopBtn.layer.masksToBounds = true
        playStopBtn.addTarget(self, action: #selector(playOrStop(sender:)), for: .touchDown)
        
        loopBtn.setImage(#imageLiteral(resourceName: "Loop"), for: .normal)
        loopBtn.layer.borderColor = UIColor.lightGray.cgColor
        loopBtn.backgroundColor = UIColor.clear
        loopBtn.layer.borderWidth = 2.0
        loopBtn.layer.cornerRadius = loopBtn.bounds.size.width / 2
        loopBtn.layer.masksToBounds = true
        loopBtn.tintColor = UIColor.gray
        loopBtn.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        loopBtn.addTarget(self, action: #selector(loop(sender:)), for: .touchDown)

        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reset()
    }
    
    func reset() {
        if PlaybackEngine.shared.isReadyToPlay() {
            playStopBtn.isUserInteractionEnabled = true
        }
        if PlaybackEngine.shared.isPlaying {
            didStartPlaying()
        } else {
            didFinishPlaying()
        }
        if PlaybackEngine.shared.isLooping {
            didStartLoop()
        } else {
            didFinishLoop()
        }
        if let block = PlaybackEngine.shared.loadedBlock {
            infoLabel.text = "\(block.name) - \(block.composedBy)"
        }
    }
    
    
    func playOrStop(sender: UIButton!) {
        if !sender.isSelected {
            if PlaybackEngine.shared.isReadyToPlay() {
                PlaybackEngine.shared.playSequence()
                sender.isSelected = true
                sender.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
            }
        } else {
            PlaybackEngine.shared.stopSequence()
            sender.isSelected = false
            sender.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 2.0)
        }
    }
    
    func loop(sender: UIButton!) {
        if !sender.isSelected {
            PlaybackEngine.shared.startLoop()
            sender.isSelected = true
            sender.layer.borderColor = UIColor.orange.cgColor
            sender.tintColor = UIColor.orange
        } else {
            PlaybackEngine.shared.stopLoop()
            sender.isSelected = false
            sender.layer.borderColor = UIColor.lightGray.cgColor
            sender.tintColor = UIColor.lightGray
        }
    }
    
    func updateTime(currentTime: AVMusicTimeStamp) {
        playtimeDelegate?.updateTime(currentTime: currentTime)
    }
    func didFinishPlaying() {
        self.playStopBtn.isSelected = false
        playStopBtn.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 2.0)
    }
    func didStartPlaying() {
        self.playStopBtn.isSelected = true
        playStopBtn.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    }
    func didLoadBlock(block: MusicBlock) {
        playStopBtn.isUserInteractionEnabled = true
        infoLabel.text = "\(block.name) - \(block.composedBy)"
    }
    
    func didStartLoop() {
        loopBtn.isSelected = true
        loopBtn.layer.borderColor = UIColor.orange.cgColor
        loopBtn.tintColor = UIColor.orange
    }
    
    func didFinishLoop() {
        loopBtn.isSelected = false
        loopBtn.layer.borderColor = UIColor.lightGray.cgColor
        loopBtn.tintColor = UIColor.lightGray
    }
    
}

protocol PlayControlBarDelegate {
    func updateTime(currentTime: AVMusicTimeStamp)
}

