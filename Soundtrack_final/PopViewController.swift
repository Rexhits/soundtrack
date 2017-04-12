//
//  PopViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/18/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import SwiftyJSON

class PopViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var chooseClipBtn: STToolbarButton!
    @IBOutlet weak var changeParameterBtn: STToolbarButton!
    @IBOutlet weak var topbar: UISegmentedControl!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var blocks = [MusicBlock]()
    var parameters = ["Number of bars", "Note Density"]
    var blockSerializer: MusicBlockSerializer!
    var showBlocks = true
    var centerPoint: CGPoint!
    
    var delegate: PopViewDelegate?
    
    override func viewDidLoad() {
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.isHidden = true
        chooseClipBtn.isOn = true
        topbar.layer.borderColor = UIColor.clear.cgColor
        topbar.layer.cornerRadius = 0
        topbar.layer.borderWidth = 1.5
        slider.isHidden = true
        self.view.backgroundColor = UIColor.darkGray
        self.centerPoint = self.view.center
        self.refreshList()
        self.collectionView.reloadData()
        blockSerializer = MusicBlockSerializer()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showBlocks {
            return blocks.count
        } else {
            return parameters.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: "collectionCell", for: indexPath) as! PopViewCollectionCell
        if showBlocks {
            cell.title.text = self.blocks[indexPath.row].name
        } else {
            cell.title.text = self.parameters[indexPath.row]
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !showBlocks {
            self.slider.isHidden = false
        }
        PlaybackEngine.shared.addMusicBlock(musicBlock: blocks[indexPath.row])
        PlaybackEngine.shared.playSequence()
        delegate?.blockSelected(sender: collectionView.cellForItem(at: indexPath) as! PopViewCollectionCell, block: blocks[indexPath.row])
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if !showBlocks {
            self.slider.isHidden = true
        }
        PlaybackEngine.shared.stopSequence()
        delegate?.blockDeselected(sender: collectionView.cellForItem(at: indexPath) as! PopViewCollectionCell)
    }
    
    @IBAction func showParameterControl(_ sender: STToolbarButton) {
        self.chooseClipBtn.isOn = false
        sender.isOn = true
        self.topbar.isHidden = true
        self.showBlocks = false
        self.collectionView.reloadData()
    }

    @IBAction func showClipSelector(_ sender: STToolbarButton) {
        self.changeParameterBtn.isOn = false
        sender.isOn = true
        slider.isHidden = true
        self.topbar.isHidden = false
        self.showBlocks = true
        self.collectionView.reloadData()
    }
    
    func dropDown() {
        UIView.animate(withDuration: 0.5, animations: {
            self.view.center = CGPoint(x: self.centerPoint.x, y: UIScreen.main.bounds.height)
        }, completion: { _ in
            self.view.isHidden = true
        })
    }
    
    func pullUp() {
        self.view.isHidden = false
        self.collectionView.reloadData()
        UIView.animate(withDuration: 0.5, animations: {
            self.view.center = self.centerPoint
        }, completion: nil)
        
    }
    @IBAction func done(_ sender: UIButton) {
        PlaybackEngine.shared.stopSequence()
        self.dropDown()
        delegate?.done()
    }
    
//    func blockConfigured(block: MusicBlock) {
//        self.blocks.append(block)
//        self.collectionView.reloadData()
//    }
    
    func refreshList() {
        Server.get(api: "users/current", body: nil) { (response, err, errCode) in
            guard response != nil else {return}
            let res = JSON(response!)
            for i in res["savedBlocks"].arrayValue {
                self.blocks.append(self.blockSerializer.getMusicBlock(json: i))
            }
            self.collectionView.reloadData()
        }
//        let files = Bundle.main.paths(forResourcesOfType: "mid", inDirectory: nil)
//        for i in files {
//            if let url = URL.init(string: i) {
//                blocks.append(MusicBlock(name: url.fileName(), composedBy: "default", midiFile: url))
//            }
//        }
    }
    
}


protocol PopViewDelegate {
    func blockSelected(sender: PopViewCollectionCell, block: MusicBlock)
    func blockDeselected(sender: PopViewCollectionCell)
    func done()
}
