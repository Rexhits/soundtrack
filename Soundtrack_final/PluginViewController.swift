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
    
    @IBOutlet var tabbar: UITabBar!
    @IBOutlet var interfaceItem: UITabBarItem!
    @IBOutlet var presetItem: UITabBarItem!
    @IBOutlet weak var presetView: UITableView!
    public var pluginView: UIView?
    public var isEffect: Bool!
    var activityIndicator: UIActivityIndicatorView!
    public var preset: [AUAudioUnitPreset]!
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
        tabbar.barTintColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let au = PlaybackEngine.shared.selectedTrack.selectedUnit {
            self.showPluginView(au: au)
        }
        let titleBarHeight = self.navigationController?.navigationBar.bounds.size.height
        let toolbarHeight = tabbar.frame.height
        rect = CGRect(x: 0, y: titleBarHeight!, width: self.view.frame.width, height: self.view.frame.height - toolbarHeight - titleBarHeight!)
        tabbar.frame = CGRect(x: 0, y: self.view.frame.height - toolbarHeight, width: self.view.frame.width, height: toolbarHeight)
        presetView.frame = rect
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
                pView.frame = rect
                view.addSubview(pView)
                view.bringSubview(toFront: pView)
            }
        } else {
            presetView.reloadData()
            pluginView?.removeFromSuperview()
            if preset.isEmpty || preset[0].name.isEmpty {
            } else {
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return preset.count
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
        cell.textLabel?.text = preset[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        PlaybackEngine.shared.selectedTrack.selectedUnit!.currentPreset = preset[indexPath.row]
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
        PlaybackEngine.shared.playSequence()
    }
}
