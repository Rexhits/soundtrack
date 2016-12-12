//
//  MixerViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import AVFoundation

class MixerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let pickerView = UIPickerView()
    
    @IBOutlet weak var mixerTable: UITableView!
    let engine = PlaybackEngine.shared
    var subVC: MixerSubviewController!
    override func viewDidLoad() {
        mixerTable.delegate = self
        mixerTable.dataSource = self
        pickerView.delegate = self
        pickerView.dataSource = self
        getEffectList()
    }
    
    private var selectedIndexPath: IndexPath!
    
    private var pluginManager: PluginManager!
    
    private var plugins: [String]!
    private var cds: [AudioComponentDescription]!
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return engine.tracks.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Track\(section + 1): \(engine.tracks[section].name!)"
    }
    
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = UIColor.white
            headerView.textLabel?.text = "Track\(section + 1): \(engine.tracks[section].name!)"
            headerView.contentView.backgroundColor = UIColor.red
//            headerView.contentView.layer.cornerRadius = 10
//            headerView.textLabel?.textAlignment = NSTextAlignment.center
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let track = engine.tracks[section]
        if track.type == .instrument {
            if !track.effects.isEmpty {
                return track.effects.count + 2
            } else {
                return 2
            }
        } else {
            if !track.effects.isEmpty {
                return track.effects.count + 1
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = mixerTable.dequeueReusableCell(withIdentifier: "mixerCell", for: indexPath)
        let track = engine.tracks[indexPath.section]
        cell.selectionStyle = UITableViewCellSelectionStyle.default
        let selView = UIView()
        selView.backgroundColor = UIColor.orange
        cell.selectedBackgroundView = selView
        cell.textLabel?.highlightedTextColor = UIColor.white
        cell.detailTextLabel?.highlightedTextColor = UIColor.white
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        cell.addGestureRecognizer(tap)
        cell.textLabel?.text = track.instrument?.name
        if track.type == .instrument {
            if indexPath.row == 0 {
                cell.textLabel?.text = track.instrument?.name
                cell.detailTextLabel?.text = "Instrument"
                cell.detailTextLabel?.isHidden = false
            }
            else if !track.effects.isEmpty && indexPath.row < track.effects.count + 1{
                print(track.effects.count)
                cell.textLabel?.text = track.effects[indexPath.row - 1].name
                cell.detailTextLabel?.text = "Effect"
                cell.detailTextLabel?.isHidden = false
            }
            else if indexPath.row == self.mixerTable.numberOfRows(inSection: indexPath.section) - 1 {
                cell.detailTextLabel?.isHidden = true
                cell.textLabel?.text = "Mixer"
//                cell.selectionStyle = UITableViewCellSelectionStyle.none
                cell.removeGestureRecognizer(tap)
            }
        } else {
//            if !track.effects.isEmpty {
//                cell.textLabel?.text = track.effects[indexPath.row].name
//                cell.detailTextLabel?.text = "Effect"
//            }
        }
        return cell
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        let track = engine.tracks[indexPath.section]
        engine.selectedTrack = track
        if let subVC = self.subVC {
            subVC.view.removeFromSuperview()
            subVC.removeFromParentViewController()
        }
        if indexPath.row != self.mixerTable.numberOfRows(inSection: indexPath.section) - 1 {
            if track.type == .instrument {
                if let unit = engine.selectedTrack.instrument {
                    engine.selectedTrack.selectedUnit = unit.auAudioUnit
                }
            } else {
                if !track.effects.isEmpty {
                    engine.selectedTrack.selectedUnit = track.effects[indexPath.row].auAudioUnit
                }
            }
        } else {
            pickerView.removeFromSuperview()
            subVC = storyboard!.instantiateViewController(withIdentifier: "mixerSubView") as! MixerSubviewController
            subVC.view.frame = CGRect(x: 0, y: view.frame.height - 200, width: view.frame.width, height: 200)
            subVC.view.backgroundColor = UIColor(white: 1, alpha: 0.6)
            subVC.titleStr = "Mixer Control on \(engine.tracks[indexPath.section].name!)"
            self.view.addSubview(self.subVC.view)
            self.addChildViewController(self.subVC)
            self.subVC.didMove(toParentViewController: self)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        selectedIndexPath = indexPath
        if let subVC = self.subVC {
            subVC.view.removeFromSuperview()
            subVC.removeFromParentViewController()
        }
        let add = UITableViewRowAction(style: .default, title: "Insert Effect") {_,_ in
            let track = self.engine.tracks[indexPath.section]
            self.engine.selectedTrack = track
            self.pickerView.backgroundColor = UIColor(white: 1, alpha: 0.9)
            self.pickerView.frame = CGRect(x: 0, y: self.view.frame.height - 300, width: self.view.frame.width, height: 300)
            self.view.addSubview(self.pickerView)
        }
        let remove = UITableViewRowAction(style: .default, title: "Remove Insert") {_,_ in 
            let track = self.engine.tracks[indexPath.section]
            self.engine.selectedTrack = track
            PlaybackEngine.shared.removeEffect(index: indexPath.row - 1)
            self.mixerTable.reloadData()
        }
        
        if indexPath.row != 0 && indexPath.row != self.mixerTable.numberOfRows(inSection: indexPath.section) - 1 {
            return [remove, add]
        } else {
            return [add]
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == self.mixerTable.numberOfRows(inSection: indexPath.section) - 1 {
            return false
        } else {
            return true
        }
    }
    
    func getEffectList() {
        pluginManager = PluginManager() {
            self.plugins = [String]()
            self.cds = [AudioComponentDescription]()
            for i in self.pluginManager._availableEffects {
                self.plugins.append(i.name)
                self.cds.append(i.audioComponentDescription)
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        self.mixerTable.reloadData()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return plugins.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return plugins[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        PlaybackEngine.shared.addNode(type: PlaybackEngine.trackType.audio, cds[row], completionHandler: {
            self.mixerTable.reloadData()
            pickerView.removeFromSuperview()
        })
    }
    
    func doubleTapped() {
        self.performSegue(withIdentifier: "selectComponent", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectComponent" {
            let destination = segue.destination as! AUListViewController
            if selectedIndexPath.row == 0 {
                destination.pluginType = 0
            } else {
                destination.pluginType = 1
            }
        }
    }
}
