//
//  MixerViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import AVFoundation

class MixerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MixerCellDelegate {
    
    
    @IBOutlet weak var mixerTable: UICollectionView!
    
    
    @IBOutlet weak var playControlBar: PlayControlBarView!
    
    
    let engine = PlaybackEngine.shared
    override func viewDidLoad() {
        mixerTable.delegate = self
        mixerTable.dataSource = self
        mixerTable.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor.gray
        randomColor()
        mixerTable.allowsMultipleSelection = true
    }
    
    var selectedIndexPath: IndexPath!
    
    
    func goBack() {
        print("called")
        self.performSegue(withIdentifier: "returnToMixer", sender: self)
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        playControlBar.reset()
        self.mixerTable.reloadData()
    }
    
        
    func doubleTapped() {
        self.performSegue(withIdentifier: "selectComponent", sender: self)
    }
    
    
    
    func randomColor() {
        for i in engine.tracks {
            if i.trackColor == nil {
                let hue = CGFloat(arc4random() & 256 / 256)
                let saturation = CGFloat(arc4random() & 256 / 256) + 0.5
                let brightness = CGFloat(arc4random() & 256 / 256) + 0.5
                i.trackColor = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return engine.tracks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = mixerTable.dequeueReusableCell(withReuseIdentifier: "mixerCell", for: indexPath) as! MixerCellView
        cell.contentView.backgroundColor = engine.tracks[indexPath.row].trackColor
        cell.trackIndexLabel.text = "TRACK\(indexPath.row + 1)"
        cell.trackNameLabel.text = engine.tracks[indexPath.row].name!
        cell.delegate = self
        cell.indexPath = indexPath
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let track = self.engine.tracks[indexPath.row]
        self.engine.selectedTrack = track
        self.selectedIndexPath = indexPath
        self.performSegue(withIdentifier: "showTrack", sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

    }
    
    func openCellSubview(cell: MixerCellView, indexPath: IndexPath) {
        cell.subVC = storyboard!.instantiateViewController(withIdentifier: "mixerSubView") as? MixerSubviewController
        if let subVC = cell.subVC {
            subVC.view.frame = cell.bounds
            subVC.view.backgroundColor = UIColor(white: 1, alpha: 0.7)
            subVC.titleStr = ""
            subVC.trackNum = indexPath.row
            self.addChildViewController(subVC)
            subVC.didMove(toParentViewController: self)
            UIView.animate(withDuration: 0.4, animations: ({
                UIView.setAnimationTransition(.flipFromLeft, for: cell.contentView, cache: true)
                cell.contentView.addSubview(subVC.view)
            }), completion: nil)
        }

    }

    func closeCellSubview(cell: MixerCellView, indexPath: IndexPath, animated: Bool) {
        if let subVC = cell.subVC {
            UIView.animate(withDuration: 0.4, animations: ({
                UIView.setAnimationTransition(.flipFromRight, for: cell.contentView, cache: true)
                subVC.view.removeFromSuperview()
                subVC.removeFromParentViewController()
            }), completion: { completion in
                cell.subVC = nil
            })
        }
    }
    
}