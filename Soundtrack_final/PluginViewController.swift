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

    public var preset: [AUAudioUnitPreset]!
    public var name: String!
    var rect: CGRect!
    override func viewDidLoad() {
        self.name = PlaybackEngine.shared.selectedTrack.instrument?.name
        self.preset = PlaybackEngine.shared.selectedTrack.selectedUnitPreset
        if let unit = PlaybackEngine.shared.selectedTrack.selectedUnit {
            self.showPluginView(unit: unit)
        }
        tabbar.delegate = self
        presetView.delegate = self
        presetView.dataSource = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let titleBarHeight = self.navigationController?.navigationBar.bounds.size.height
        let toolbarHeight = tabbar.frame.height
        rect = CGRect(x: 0, y: titleBarHeight!, width: self.view.frame.width, height: self.view.frame.height - toolbarHeight - titleBarHeight!)
        tabbar.frame = CGRect(x: 0, y: self.view.frame.height - toolbarHeight, width: self.view.frame.width, height: toolbarHeight)
        presetView.frame = rect
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
                pView.frame = rect
                view.addSubview(pView)
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
        cell.selectedBackgroundView = selView
        cell.textLabel?.highlightedTextColor = UIColor.white
        cell.detailTextLabel?.highlightedTextColor = UIColor.white
        cell.textLabel?.text = preset[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        PlaybackEngine.shared.selectedTrack.selectedUnit!.currentPreset = preset[indexPath.row]
    }
    
    private func showPluginView(unit: AUAudioUnit) {
        unit.requestViewController { [weak self] viewController in
            guard let strongSelf = self else {return}
            guard let vc = viewController, let view = vc.view else {
                /*
                 Show placeholder text that tells the user the audio unit has
                 no view.
                 */
                return
                
            }
            strongSelf.pluginView = view
        }
    }
}
