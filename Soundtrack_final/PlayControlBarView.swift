//
//  PlayToolBarView.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/12/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import AVFoundation

class PlayControlBarView: UITabBar, PlaybackEngineDelegate {
    
    var playOrStopItem: UIButton!
    var loopItem: UIButton!
    var label: UILabel!
    var playtimeDelegate: PlayControlBarDelegate?
    override func awakeFromNib() {
        self.layer.masksToBounds = true
        PlaybackEngine.shared.delegate = self
        self.barStyle = .black
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let x = self.bounds.size.height - 19
        playOrStopItem = UIButton(frame: CGRect(x: 20, y: (self.bounds.size.height - x) / 2, width: x, height: x))
        
        playOrStopItem.setImage(#imageLiteral(resourceName: "Play"), for: .normal)
        playOrStopItem.setImage(#imageLiteral(resourceName: "Pause"), for: .selected)
        playOrStopItem.layer.borderColor = UIColor.orange.cgColor
        playOrStopItem.backgroundColor = UIColor.clear
        playOrStopItem.layer.borderWidth = 2.0
        playOrStopItem.layer.cornerRadius = playOrStopItem.bounds.size.width / 2
        playOrStopItem.layer.masksToBounds = true
        playOrStopItem.imageView?.tintColor = UIColor.orange
        playOrStopItem.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 2.0)
        playOrStopItem.addTarget(self, action: #selector(playOrStop(sender:)), for: .touchDown)
        
        loopItem = UIButton(frame: CGRect(x: self.bounds.size.width - 20, y: (self.bounds.size.height - x) / 2, width: x, height: x))
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
        loopItem.setImage(#imageLiteral(resourceName: "Loop"), for: .normal)
        loopItem.layer.borderColor = UIColor.lightGray.cgColor
        loopItem.backgroundColor = UIColor.clear
        loopItem.layer.borderWidth = 2.0
        loopItem.layer.cornerRadius = loopItem.bounds.size.width / 2
        loopItem.layer.masksToBounds = true
        loopItem.imageView?.tintColor = UIColor.lightGray
        loopItem.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        loopItem.addTarget(self, action: #selector(loop(sender:)), for: .touchDown)
        
        label = UILabel(frame: CGRect(x: 20, y: (self.bounds.size.height - x) / 2, width: self.bounds.size.width - 20, height: x))
        if let block = PlaybackEngine.shared.loadedBlock {
            if let label = self.label {
                label.text = "\(block.name) - \(block.composedBy)"
            }
        }
        label.textColor = UIColor.orange
        label.textAlignment = NSTextAlignment.center
        label.backgroundColor = UIColor.clear
        label.clipsToBounds = true
        label.layer.masksToBounds = true
        self.addSubview(playOrStopItem)
        self.addSubview(loopItem)
        self.addSubview(label)
        self.autoresizesSubviews = true
    }
    
    func reset() {
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
            if let label = self.label {
                label.text = "\(block.name) - \(block.composedBy)"
            }
        }
    }
    
    
    func playOrStop(sender: UIButton!) {
        if !sender.isSelected {
            PlaybackEngine.shared.playSequence()
            sender.isSelected = true
            playOrStopItem.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
        } else {
            PlaybackEngine.shared.stopSequence()
            sender.isSelected = false
            playOrStopItem.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 2.0)
        }
    }
    
    func loop(sender: UIButton!) {
        if !sender.isSelected {
            PlaybackEngine.shared.startLoop()
            sender.isSelected = true
            sender.layer.borderColor = UIColor.orange.cgColor
            sender.imageView?.tintColor = UIColor.orange
        } else {
            PlaybackEngine.shared.stopLoop()
            sender.isSelected = false
            sender.layer.borderColor = UIColor.lightGray.cgColor
            sender.imageView?.tintColor = UIColor.lightGray
        }
    }
    
    func updateTime(currentTime: AVMusicTimeStamp) {
        playtimeDelegate?.updateTime(currentTime: currentTime)
    }
    func didFinishPlaying() {
        self.playOrStopItem.isSelected = false
        playOrStopItem.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 2.0)
    }
    func didStartPlaying() {
        self.playOrStopItem.isSelected = true
        playOrStopItem.imageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    }
    func didLoadBlock(block: MusicBlock) {
        if let label = self.label {
            label.text = "\(block.name) - \(block.composedBy)"
        }
    }
    
    func didStartLoop() {
        loopItem.isSelected = true
        loopItem.layer.borderColor = UIColor.orange.cgColor
        loopItem.imageView?.tintColor = UIColor.orange
    }
    
    func didFinishLoop() {
        loopItem.isSelected = false
        loopItem.layer.borderColor = UIColor.lightGray.cgColor
        loopItem.imageView?.tintColor = UIColor.lightGray
    }
    
}

protocol PlayControlBarDelegate {
    func updateTime(currentTime: AVMusicTimeStamp)
}
