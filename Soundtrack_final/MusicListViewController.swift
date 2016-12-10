//
//  MusicListViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit

class MusicListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
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
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return musicList.count
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        <#code#>
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = musicTable.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath)
        let selView = UIView()
        selView.backgroundColor = UIColor.orange
        selView.layer.cornerRadius = 10
        cell.selectedBackgroundView = selView
        cell.textLabel?.highlightedTextColor = UIColor.white
        cell.detailTextLabel?.highlightedTextColor = UIColor.white
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        cell.addGestureRecognizer(tap)
        cell.textLabel?.text = musicList[indexPath.row].name
        return cell
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
//        PlaybackEngine.shared.playSequence()
    }
}
