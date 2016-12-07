//
//  AUViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import CoreAudioKit

class PluginViewController: UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var tabbar: UITabBar!
    @IBOutlet var interfaceItem: UITabBarItem!
    @IBOutlet var presetItem: UITabBarItem!
    @IBOutlet var containerView: UIView!
    let cell = UITableViewCell(style: .default, reuseIdentifier: "presetCell")
    public var pluginView: UIView?
    public var presetView = UITableView()
    public var preset: [AUAudioUnitPreset]!
    public var name: String!
    override func viewDidLoad() {
        tabbar.delegate = self
        presetView.delegate = self
        presetView.dataSource = self
        presetView.frame = self.containerView.bounds
        if pluginView == nil {
            interfaceItem.isEnabled = false
            tabbar.selectedItem = presetItem
            tabBar(tabbar, didSelect: presetItem)
        } else {
            tabbar.selectedItem = interfaceItem
            tabBar(tabbar, didSelect: interfaceItem)
        }
    }
    
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if item == interfaceItem {
            if let pView = pluginView {
                presetView.removeFromSuperview()
                pView.frame = self.containerView.bounds
                containerView.addSubview(pView)
                self.title = name
            }
        } else {
            presetView.reloadData()
            pluginView?.removeFromSuperview()
            containerView.addSubview(presetView)
            if preset.isEmpty || preset[0].name.isEmpty {
                self.title = "Preset Not Found"
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return preset.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell.textLabel?.text = preset[indexPath.row].name
        return cell
    }
}
