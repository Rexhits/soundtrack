//
//  MixerViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit

class MixerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var mixerTable: UITableView!
    let engine = PlaybackEngine.shared
    
    override func viewDidLoad() {
        mixerTable.delegate = self
        mixerTable.dataSource = self
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return engine.tracks.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return engine.tracks[section].name
    }
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = NSTextAlignment.center
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let track = engine.tracks[section]
        if track.type == .instrument {
            if let effects = track.effects {
                return effects.count + 1
            } else {
                return 1
            }
        } else {
            if let effects = track.effects {
                return effects.count
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
        selView.layer.cornerRadius = 10
        cell.selectedBackgroundView = selView
        cell.textLabel?.highlightedTextColor = UIColor.white
        cell.detailTextLabel?.highlightedTextColor = UIColor.white
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        cell.addGestureRecognizer(tap)
        cell.textLabel?.text = track.instrument?.name
        if track.type == .instrument {
            cell.textLabel?.text = track.instrument?.name
            cell.detailTextLabel?.text = "Instrument"
            if let effects = track.effects {
                cell.textLabel?.text = effects[indexPath.row - 1].name
                cell.detailTextLabel?.text = "Effect"
            }
        } else {
            if let effects = track.effects {
                cell.textLabel?.text = effects[indexPath.row].name
                cell.detailTextLabel?.text = "Effect"
            }
        }
        return cell
    }
    
    func doubleTapped() {
        self.performSegue(withIdentifier: "selectComponent", sender: self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let track = engine.tracks[indexPath.section]
        engine.selectedTrack = track
        if track.type == .instrument {
            if let unit = engine.selectedTrack.instrument {
                engine.selectedTrack.selectedUnit = unit.auAudioUnit
            }
        } else {
            if let effects = engine.selectedTrack.effects {
                engine.selectedTrack.selectedUnit = effects[indexPath.row].auAudioUnit
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.mixerTable.reloadData()
    }
}
