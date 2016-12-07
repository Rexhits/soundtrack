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
    
    struct componentDecription: CustomStringConvertible, Equatable {
        var name: String!
        var version: String!
        var cd: AudioComponentDescription!
        var description: String {
            return name
        }
        static func ==(lhs: componentDecription, rhs: componentDecription) -> Bool {
            return lhs.cd.componentType == rhs.cd.componentType && lhs.cd.componentSubType == rhs.cd.componentSubType && lhs.cd.componentFlags == rhs.cd.componentFlags && lhs.cd.componentFlagsMask == rhs.cd.componentFlagsMask
        }
    }
    
    @IBOutlet var auTable: UITableView!
    var pluginView: UIView!
    var pluginPreset: [AUAudioUnitPreset]!
    var pluginName: String!
    public var pluginType = 0 {
        didSet {
            self.auTable.reloadData()
        }
    }
    private var pluginManager: PluginManager!
    private var plugins = [String: [componentDecription]]()
    
    override func viewDidLoad() {
        self.title = "Instrument"
        auTable.delegate = self
        auTable.dataSource = self
        pluginManager = PluginManager() {
            if self.pluginType == 0 {
                self.plugins = [String: [componentDecription]]()
                for i in self.pluginManager._availableInstruments {
                    if self.plugins[i.manufacturerName] == nil {
                        if i.manufacturerName != "Apple" {
                            self.plugins[i.manufacturerName] = [componentDecription]()
                        }
                    }
                    if i.manufacturerName != "Apple" {
                        self.plugins[i.manufacturerName]!.append(componentDecription(name: i.name, version: i.versionString, cd: i.audioComponentDescription))
                    }
                }
            } else {
                self.plugins = [String: [componentDecription]]()
                for i in self.pluginManager._availableEffects {
                    if self.plugins[i.manufacturerName] == nil {
                        self.plugins[i.manufacturerName] = [componentDecription]()
                    }
                        self.plugins[i.manufacturerName]!.append(componentDecription(name: i.name, version: i.versionString, cd: i.audioComponentDescription))
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
        let key = [String](plugins.keys)[indexPath.section]
        let values = plugins[key]!
        let value = values[indexPath.row]
        cell.textLabel!.text = value.name
        cell.detailTextLabel!.text = value.version
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        pluginView = nil
        pluginPreset = nil
        pluginName = nil
        let key = [String](plugins.keys)[indexPath.section]
        let values = plugins[key]!
        let value = values[indexPath.row]
        pluginManager.selectAudioUnitWithComponentDescription(value.cd, completionHandler: { unit, node, preset in
//            PlaybackEngine.shared.newNode(type: .instrument, component: node)
//            PlaybackEngine.shared.addMusicBlock(musicBlock: self.block)
//            PlaybackEngine.shared.playSequence()
            self.pluginName = node.name
            self.pluginPreset = preset
            self.showPluginView(unit: unit)
            self.auTable.reloadData()
        })
    }
    
    private func showPluginView(unit: AUAudioUnit) {
        unit.requestViewController { [weak self] viewController in
            guard let vc = viewController, let view = vc.view else {
                /*
                 Show placeholder text that tells the user the audio unit has
                 no view.
                 */
                return
            }
            self?.pluginView = view
            
        }
        self.performSegue(withIdentifier: "showPluginView", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPluginView" {
            let destination = segue.destination as! PluginViewController
            destination.pluginView = self.pluginView
            destination.preset = self.pluginPreset
            destination.name = self.pluginName
        }
    }
    
}
