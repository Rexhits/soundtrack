//
//  MixerPopoverViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/12/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import AVFoundation

class MixerPopoverViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MixerCellDelegate {
    
    @IBOutlet weak var playControlBar: UIView!
    @IBOutlet weak var trackTable: UICollectionView!
    let engine = PlaybackEngine.shared
    var selectedIndexPath: IndexPath!
    var removeButton: UIButton!
    var subView: UIView!
    private var adding: Bool!
    
    override func viewDidLoad() {
        trackTable.delegate = self
        trackTable.dataSource = self
        view.backgroundColor = engine.selectedTrack.trackColor
        trackTable.backgroundColor = UIColor.clear
        let label = UILabel(frame: CGRect(x: 0, y: view.frame.height / 2 - 20, width: view.frame.width, height: 40))
        label.textColor = UIColor.lightGray
        label.text = engine.selectedTrack.name
        label.font = label.font.withSize(40)
        label.textAlignment = NSTextAlignment.center
        self.view.addSubview(label)
        self.view.bringSubview(toFront: trackTable)
    }
    
    func returnToMixer() {
        self.performSegue(withIdentifier: "returnToMixer", sender: self)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if engine.selectedTrack.type == .instrument {
            return 2
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if engine.selectedTrack.type == .instrument {
            if section == 0 {
                return 1
            } else {
                return engine.selectedTrack.effects.count + 1
            }
        } else {
            return engine.selectedTrack.effects.count + 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = trackTable.dequeueReusableCell(withReuseIdentifier: "pluginCell", for: indexPath) as! MixerCellView
        cell.trackNameLabel.textColor = UIColor.white
        cell.delegate = self
        cell.indexPath = indexPath
        cell.closeSubview(sender: self, animated: false)
        if engine.selectedTrack.type == .instrument {
            if indexPath.section == 0 {
                cell.contentView.backgroundColor = UIColor.orange.withAlphaComponent(0.8)
                cell.trackIndexLabel.text = "Instrument"
                cell.trackNameLabel.text = engine.selectedTrack.instrument!.name
            } else {
                if indexPath.row == self.trackTable.numberOfItems(inSection: indexPath.section) - 1 {
                    cell.contentView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
                    cell.trackIndexLabel.text = "Effect"
                    cell.trackNameLabel.text = "+"
                } else {
                    cell.contentView.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
                    cell.trackIndexLabel.text = "Effect\(indexPath.row + 1)"
                    cell.trackNameLabel.text = engine.selectedTrack.effects[indexPath.row].name
                }
            }
        } else {
            if indexPath.row == self.trackTable.numberOfItems(inSection: indexPath.section) - 1 {
                cell.contentView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.8)
                cell.trackIndexLabel.text = "New"
                cell.trackNameLabel.text = "Effect"
            } else {
                cell.contentView.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
                cell.trackIndexLabel.text = "Effect\(indexPath.row + 1)"
                cell.trackNameLabel.text = engine.selectedTrack.effects[indexPath.row].name
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
        
        if indexPath.section != 0 && indexPath.row == self.trackTable.numberOfItems(inSection: indexPath.section) - 1 {
            self.adding = true
            engine.selectedTrack.selectedNode = nil
            engine.selectedTrack.selectedUnit = nil
            engine.selectedTrack.selectedUnitPreset = [AUAudioUnitPreset]()
            engine.selectedTrack.selectedUnitDescription = nil
            self.performSegue(withIdentifier: "selectComponent", sender: self)
            
        } else if (indexPath.section != 0 && indexPath.row != self.trackTable.numberOfItems(inSection: indexPath.section) - 1) {
            self.adding = false
            engine.selectedTrack.selectedNode = engine.selectedTrack.effects[indexPath.row]
            engine.selectedTrack.selectedUnit = engine.selectedTrack.effects[indexPath.row].auAudioUnit
            engine.selectedTrack.selectedUnitPreset = engine.selectedTrack.effects[indexPath.row].auAudioUnit.factoryPresets ?? []
            engine.selectedTrack.selectedUnitDescription = engine.selectedTrack.effects[indexPath.row].audioComponentDescription
            self.performSegue(withIdentifier: "showPluginView", sender: self)
        } else {
            self.adding = false
            if indexPath.section == 0 {
                engine.selectedTrack.selectedNode = engine.selectedTrack.instrument
                engine.selectedTrack.selectedUnit = engine.selectedTrack.instrument?.auAudioUnit
                engine.selectedTrack.selectedUnitPreset = engine.selectedTrack.instrument?.auAudioUnit.factoryPresets ?? []
                engine.selectedTrack.selectedUnitDescription = engine.selectedTrack.instrument?.audioComponentDescription
                self.performSegue(withIdentifier: "showPluginView", sender: self)
            }
            
        }
    }
    
    
    func openCellSubview(cell: MixerCellView, indexPath: IndexPath) {
        self.selectedIndexPath = indexPath
        if indexPath.section == 0 {
            subView = UIView()
            subView.frame = cell.contentView.frame
            subView.backgroundColor = UIColor(white: 1, alpha: 0.8)
            let width = subView.frame.width
            let height = CGFloat(subView.frame.height / 4)
            let x = CGFloat(0)
            let y = subView.frame.height / 2 - (height / 2)
            let addButton = UIButton(frame: CGRect(x: x, y: y, width: width, height: height))
            addButton.setTitle("Change Instrument", for: .normal)
            addButton.titleLabel?.font = addButton.titleLabel?.font.withSize(20)
            addButton.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
            addButton.layer.cornerRadius = 10
            addButton.addTarget(self, action: #selector(openAUList(sender:)), for: .touchUpInside)
            addButton.addTarget(self, action: #selector(buttonTouchDown(sender:)), for: .touchDown)
            addButton.addTarget(self, action: #selector(buttonTouchReleased(sender:)), for: .touchUpOutside)
            self.subView.addSubview(addButton)
            UIView.animate(withDuration: 0.4, animations: ({
                UIView.setAnimationTransition(.flipFromLeft, for: cell.contentView, cache: true)
                cell.contentView.addSubview(self.subView)
            }), completion: nil)
        } else if indexPath.row != self.trackTable.numberOfItems(inSection: indexPath.section) - 1{
            subView = UIView()
            subView.frame = cell.contentView.frame
            subView.backgroundColor = UIColor(white: 1, alpha: 0.8)
            let width = subView.frame.width
            let height = CGFloat(subView.frame.height / 4)
            let x = CGFloat(0)
            let y1 = subView.frame.height / 2 - height - 5
            let removeButton = UIButton(frame: CGRect(x: x, y: y1, width: width, height: height))
            removeButton.setTitle("Remove Effect", for: .normal)
            removeButton.titleLabel?.font = removeButton.titleLabel?.font.withSize(20)
            removeButton.backgroundColor = UIColor.red.withAlphaComponent(0.8)
            removeButton.layer.cornerRadius = 10
            removeButton.addTarget(self, action: #selector(removeAU(sender:)), for: .touchUpInside)
            removeButton.addTarget(self, action: #selector(buttonTouchDown(sender:)), for: .touchDown)
            removeButton.addTarget(self, action: #selector(buttonTouchReleased(sender:)), for: .touchUpOutside)
            let y2 = subView.frame.height / 2 + 5
            let changeButton = UIButton(frame: CGRect(x: x, y: y2, width: width, height: height))
            changeButton.setTitle("Change Effect", for: .normal)
            changeButton.titleLabel?.font = removeButton.titleLabel?.font.withSize(20)
            changeButton.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
            changeButton.layer.cornerRadius = 10
            changeButton.addTarget(self, action: #selector(openAUList(sender:)), for: .touchUpInside)
            changeButton.addTarget(self, action: #selector(buttonTouchDown(sender:)), for: .touchDown)
            changeButton.addTarget(self, action: #selector(buttonTouchReleased(sender:)), for: .touchUpOutside)
            self.subView.addSubview(removeButton)
            self.subView.addSubview(changeButton)
            UIView.animate(withDuration: 0.4, animations: ({
                UIView.setAnimationTransition(.flipFromLeft, for: cell.contentView, cache: true)
                cell.contentView.addSubview(self.subView)
            }), completion: nil)
        }
    }
    
    func closeCellSubview(cell: MixerCellView, indexPath: IndexPath, animated: Bool) {
        if let subView = self.subView {
            if animated {
                UIView.animate(withDuration: 0.4, animations: ({
                    UIView.setAnimationTransition(.flipFromRight, for: cell.contentView, cache: true)
                    subView.removeFromSuperview()
                }), completion: { completion in
                    self.subView = nil
                })
            } else {
                subView.removeFromSuperview()
                self.subView = nil
            }
            
        }
    }
    
    
    func buttonTouchDown(sender: UIButton!) {
        sender.backgroundColor = UIColor.orange.withAlphaComponent(0.8)
    }
    
    func buttonTouchReleased(sender: UIButton!) {
        sender.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
    }
    
    func openAUList(sender: UIButton!) {
        self.adding = false
        sender.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
        self.performSegue(withIdentifier: "selectComponent", sender: self)
    }
    
    func removeAU(sender: Any!) {
        let cell = trackTable.cellForItem(at: selectedIndexPath) as! MixerCellView
        cell.closeSubview(sender: self, animated: false)
        PlaybackEngine.shared.removeEffect(index: selectedIndexPath.row)
        self.trackTable.reloadData()
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectComponent" {
            let destination = segue.destination as! AUListViewController
            if selectedIndexPath.section == 0 {
                destination.pluginType = 0
            } else {
                destination.pluginType = 1
            }
            destination.adding = self.adding
        }
        if segue.identifier == "showPluginView" {
            self.engine.restartSeq()
            let vc = segue.destination as! PluginViewController
            if selectedIndexPath.section == 0 {
                vc.isEffect = false
            } else {
                vc.isEffect = true
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        self.trackTable.reloadData()
        self.selectedIndexPath = nil
    }
    
}
