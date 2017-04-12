//
//  AUViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import CoreAudioKit
import AudioToolbox

class PluginViewController: UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playControlBar: UIView!
    @IBOutlet var tabbar: UITabBar!
    @IBOutlet var interfaceItem: UITabBarItem!
    @IBOutlet var presetItem: UITabBarItem!
    @IBOutlet weak var presetView: UITableView!
    public var pluginView: UIView?
    public var isEffect: Bool!
    var activityIndicator: UIActivityIndicatorView!
    public var preset: [AUAudioUnitPreset]!
    public var soundFont = [SoundFont]()
    public var name: String!
    var rect: CGRect!
    override func viewDidLoad() {
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        activityIndicator.color = UIColor.orange
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        self.view.isUserInteractionEnabled = false
        view.addSubview(activityIndicator)
        self.name = PlaybackEngine.shared.selectedTrack.instrument?.name
        self.preset = PlaybackEngine.shared.selectedTrack.selectedUnitPreset
        tabbar.delegate = self
        presetView.delegate = self
        presetView.dataSource = self
        presetView.backgroundColor = UIColor.clear
        view.backgroundColor = UIColor.gray
        tabbar.barTintColor = UIColor.darkText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let au = PlaybackEngine.shared.selectedTrack.selectedUnit {
            self.showPluginView(au: au)
        }
        self.addChildViewController(appDelegate.playbackController)
        appDelegate.playbackController.view.frame = self.playControlBar.bounds
        self.playControlBar.addSubview(appDelegate.playbackController.view)
        appDelegate.playbackController.didMove(toParentViewController: self)
    }
    override func viewDidAppear(_ animated: Bool) {
        if pluginView == nil {
            interfaceItem.isEnabled = false
            tabbar.selectedItem = presetItem
            tabBar(tabbar, didSelect: presetItem)
        } else {
            tabbar.selectedItem = interfaceItem
            tabBar(tabbar, didSelect: interfaceItem)
        }
        activityIndicator.stopAnimating()
        self.view.isUserInteractionEnabled = true
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item == interfaceItem {
            if let pView = pluginView {
                pView.removeFromSuperview()
                pView.frame = presetView.frame
                view.addSubview(pView)
                view.bringSubview(toFront: pView)
            }
        } else {
            pluginView?.removeFromSuperview()
            if let au = PlaybackEngine.shared.selectedTrack.selectedUnit {
                if au.audioUnitName! == "AUSampler" {
                    let files = STFileManager.shared.getAUSapmlerPresets()
                    for i in files {
//                        let path = "file://\(i)"
                        let url = URL.init(fileURLWithPath: i)
                        self.soundFont.append(SoundFont(name: url.fileName(), url: url))
                    }
                }
            }
            if preset.isEmpty || preset[0].name.isEmpty {
                
            } else {
                
            }
        }
        presetView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return preset.count
        } else {
            return soundFont.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = presetView.dequeueReusableCell(withIdentifier: "presetCell", for: indexPath)
        cell.selectionStyle = UITableViewCellSelectionStyle.default
        let selView = UIView()
        selView.backgroundColor = UIColor.orange
        selView.layer.cornerRadius = 10
        cell.textLabel?.textColor = UIColor.white
        cell.detailTextLabel?.textColor = UIColor.white
        cell.backgroundColor = UIColor.clear
        cell.selectedBackgroundView = selView
        cell.textLabel?.highlightedTextColor = UIColor.white
        cell.detailTextLabel?.highlightedTextColor = UIColor.white
        if indexPath.section == 0 {
            cell.textLabel?.text = preset[indexPath.row].name
        } else {
            cell.textLabel?.text = soundFont[indexPath.row].name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0{
            PlaybackEngine.shared.selectedTrack.selectedUnit!.currentPreset = preset[indexPath.row]
        } else {
            do {
                try PlaybackEngine.shared.selectedTrack.selectedNode?.loadPreset(at: soundFont[indexPath.row].url)
                PlaybackEngine.shared.selectedTrack.soundFont = soundFont[indexPath.row]
            } catch {
                print(error.localizedDescription)
            }
        }
        
    }
    
    private func showPluginView(au: AUAudioUnit) {
        if !isEffect {
            if PlaybackEngine.shared.selectedTrack.instrumentView != nil {
                self.pluginView = PlaybackEngine.shared.selectedTrack.instrumentView!
            } else {
                self.activityIndicator.stopAnimating()
                self.view.isUserInteractionEnabled = true
            }
        } else {
            self.pluginView = nil
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
}


