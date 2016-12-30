//
//  MusicListViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import Lockbox

class MusicListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playControlBar: UIView!
    @IBOutlet weak var musicTable: UITableView!
    var musicList = [MusicBlock]()
    var selectedIndexPath: IndexPath!
    override func viewDidLoad() {
        musicTable.delegate = self
        musicTable.dataSource = self
        let files = Bundle.main.paths(forResourcesOfType: "mid", inDirectory: nil)
        for i in files {
            if let url = URL.init(string: i) {
                musicList.append(MusicBlock(name: url.lastPathComponent, composedBy: "zzw", midiFile: url))
            }
        }
        musicTable.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor.gray
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = musicTable.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath)
        let selView = UIView()
        selView.backgroundColor = UIColor.orange
        selView.layer.cornerRadius = 10
        cell.selectedBackgroundView = selView
        cell.textLabel?.textColor = UIColor.white
        cell.backgroundColor = UIColor.clear
        cell.textLabel?.highlightedTextColor = UIColor.white
        cell.detailTextLabel?.highlightedTextColor = UIColor.white
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        cell.addGestureRecognizer(tap)
        cell.textLabel?.text = musicList[indexPath.row].name
        return cell
    }
    
    @IBAction func logout(_ sender: UIBarButtonItem) {
        print("Logged Out! \(Lockbox.archiveObject(nil, forKey: "Token")))")
        self.navigationController?.performSegue(withIdentifier: "logout", sender: self)
//        self.performSegue(withIdentifier: "logout", sender: self)
    }
    func doubleTapped() {
        self.performSegue(withIdentifier: "showMixer", sender: self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        if selectedIndexPath != indexPath {
            PlaybackEngine.shared.addMusicBlock(musicBlock: musicList[indexPath.row])
        }
        selectedIndexPath = indexPath
        STFileManager.shared.saveCurrentBlock()
//        PlaybackEngine.shared.playSequence()
    }
    override func viewWillAppear(_ animated: Bool) {
        musicTable.reloadData()
    }
}
