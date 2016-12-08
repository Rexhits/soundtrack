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
    
    
    var titleStr: String!
    @IBOutlet var auTable: UITableView!
    public var pluginType = 0 {
        didSet {
            if pluginType == 0 {
                self.titleStr = "Instrument"
            } else {
                self.titleStr = "Effect"
            }
            self.auTable.reloadData()
        }
    }
    private var pluginManager: PluginManager!
    private var plugins = [String: [componentDescription]]()
    override func viewDidLoad() {
        auTable.delegate = self
        auTable.dataSource = self
        getAUList()
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

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = auTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
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
        let key = [String](plugins.keys)[indexPath.section]
        let values = plugins[key]!
        let value = values[indexPath.row]
        cell.textLabel!.text = value.name
        cell.detailTextLabel!.text = value.version
        
        return cell
    }
    
    func doubleTapped() {
        self.performSegue(withIdentifier: "showPluginView", sender: self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = [String](plugins.keys)[indexPath.section]
        let values = plugins[key]!
        let value = values[indexPath.row]
        PlaybackEngine.shared.addNode(type: PlaybackEngine.trackType(rawValue: self.pluginType)!, value.cd, completionHandler: {})
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let cell = auTable.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if !cell.isSelected {
            self.auTable.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        let editAction = UITableViewRowAction(style: .normal, title: "Show") {_,_ in
            self.performSegue(withIdentifier: "showPluginView", sender: self)
        }
        editAction.backgroundColor = UIColor.blue
        return [editAction]
    }

    
    override func viewWillAppear(_ animated: Bool) {
        if let t = titleStr {
            self.title = t
        }
        getAUList()
    }
}
