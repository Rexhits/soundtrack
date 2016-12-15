//
//  AUListViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import AVFoundation
import CoreAudioKit

class AUListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playbackControl: PlayControlBarView!
    struct componentDescription: CustomStringConvertible {
        var name: String!
        var version: String!
        var cd: AudioComponentDescription!
        var description: String {
            return name
        }
    }
    @IBOutlet weak var actionIndicator: UIActivityIndicatorView!
    
    
    var titleStr: String! {
        didSet {
            self.title = titleStr
        }
    }
    @IBOutlet var auTable: UITableView!
    public var pluginType = 0 {
        didSet {
            self.titleStr = PlaybackEngine.shared.selectedTrack.selectedUnit?.audioUnitName
//            getAUList()
        }
    }
    private var pluginLoaded = false
    private var selectedIndexPath: IndexPath?
    private var pluginManager: PluginManager!
    private var plugins = [String: [componentDescription]]()
    override func viewDidLoad() {
        auTable.delegate = self
        auTable.dataSource = self
        getAUList()
        actionIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        actionIndicator.color = UIColor.orange
        auTable.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor.gray
    }
    
    func getAUList() {
        pluginManager = PluginManager() {
            if self.pluginType == 0 {
                self.plugins = [String: [componentDescription]]()
                for i in self.pluginManager._availableInstruments {
                    if self.plugins[i.manufacturerName] == nil {
                        if i.manufacturerName != "Apple" {
                            self.plugins[i.manufacturerName] = [componentDescription]()
                        }
                    }
                    if i.manufacturerName != "Apple" {
                        self.plugins[i.manufacturerName]!.append(componentDescription(name: i.name, version: i.versionString, cd: i.audioComponentDescription))
                    }
                }
            } else {
                self.plugins = [String: [componentDescription]]()
                for i in self.pluginManager._availableEffects {
                    if self.plugins[i.manufacturerName] == nil {
                        self.plugins[i.manufacturerName] = [componentDescription]()
                    }
                    self.plugins[i.manufacturerName]!.append(componentDescription(name: i.name, version: i.versionString, cd: i.audioComponentDescription))
                }
            }
            self.auTable.reloadData()
            if let des = PlaybackEngine.shared.selectedTrack.selectedUnitDescription {
                for (index, value) in self.plugins.enumerated() {
                    for (i,v) in value.value.enumerated() {
                        if v.cd == des {
                            let indexPath = IndexPath(row: i, section: index)
                            let cell = self.auTable.cellForRow(at: indexPath)!
                            cell.isSelected = true
                            self.auTable.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                        }
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return plugins.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if plugins.isEmpty {
            return ""
        } else {
            return [String](plugins.keys)[section]
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let key = [String](plugins.keys)[section]
        let values = plugins[key]!
        return values.count
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.textColor = UIColor.orange
            header.contentView.backgroundColor = UIColor.darkGray
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = auTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.default
        let selView = UIView()
        selView.backgroundColor = UIColor.orange
        selView.layer.cornerRadius = 10
        cell.selectedBackgroundView = selView
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.highlightedTextColor = UIColor.white
        cell.detailTextLabel?.highlightedTextColor = UIColor.white
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        cell.addGestureRecognizer(tap)
        let key = [String](plugins.keys)[indexPath.section]
        let values = plugins[key]!
        let value = values[indexPath.row]
        cell.textLabel!.text = value.name
        cell.detailTextLabel!.text = value.version
        
        return cell
    }
    
    func doubleTapped() {
        showPluginView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedIndexPath != indexPath {
            let key = [String](plugins.keys)[indexPath.section]
            let values = plugins[key]!
            let value = values[indexPath.row]
            actionIndicator.startAnimating()
            PlaybackEngine.shared.addNode(type: PlaybackEngine.trackType(rawValue: self.pluginType)!, adding: false, value.cd, completionHandler: {
                self.actionIndicator.stopAnimating()
                self.pluginLoaded = true
                self.titleStr = PlaybackEngine.shared.selectedTrack.selectedUnit?.audioUnitName
            })
        }
        selectedIndexPath = indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.pluginLoaded = false
    }
    

    
    func showPluginView() {
        var timer: Timer?
        if !pluginLoaded {
            actionIndicator.startAnimating()
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {_ in
                if self.pluginLoaded {
                    self.performSegue(withIdentifier: "showPluginView", sender: self)
                    timer!.invalidate()
                    timer = nil
                    self.actionIndicator.stopAnimating()
                }
            }
        } else {
            self.performSegue(withIdentifier: "showPluginView", sender: self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let t = titleStr {
            self.title = t
        }
        playbackControl.reset()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPluginView" {
            let vc = segue.destination as! PluginViewController
            vc.isEffect = Bool.init(self.pluginType as NSNumber)
            PlaybackEngine.shared.stopSequence()
        }
    }
}
