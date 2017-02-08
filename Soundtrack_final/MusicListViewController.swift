//
//  MusicListViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import Lockbox
import SwiftyJSON


class MusicListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var playbackBar: UIView!
    
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
        
//        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        do {
//            let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
//            let musicFiles = files.filter{$0.pathExtension == "json"}
//            for i in musicFiles {
//                do {
//                    let data = try Data.init(contentsOf: i)
//                    let json = JSON.init(data: data)
//                    musicList.append(MusicBlock(json: json))
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }
//        } catch let err as NSError {
//            print(err.localizedDescription)
//        }
        
        
        
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
    
    
    func doubleTapped() {
        self.performSegue(withIdentifier: "showMixer", sender: self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        
        if selectedIndexPath != indexPath {
            PlaybackEngine.shared.addMusicBlock(musicBlock: musicList[indexPath.row])
        }
        selectedIndexPath = indexPath
        
        
        
//        musicList[indexPath.row].trainClassifier()
        
        STFileManager.shared.saveCurrentBlock()
        
//        musicList[indexPath.row].saveJson()
        
        for i in musicList[indexPath.row].parsedTracks {
//            print("\(i.groupAnalysis())\n")
//            print("\(i.tempo)\t\(i.timeSignature)\t\(i.instrumentName)")
            print("\(i.timestampAnalysis())\n")
//            print("\(i.notes.map{$0.timeStamp})\n")
//            i.byMeasure()
            
//            print(i.getMeanNoteLength())
//            print("\(i.byMeasure().map{$0.notes.map({$0.timeStamp})})\n")
//            print("\(i.instrumentName): \(i.byMeasure().map{$0.getNoteDistribution()})\n")
        }
        
//        for i in musicList[indexPath.row].parsedTracks {
//            print("Percentage of Bass: \(i.getBassPercentage())\t")
//            print("Mean of Note Length: \(i.getMeanOfNoteLength())\t")
//            print("Max/Min of Interval: \(i.getMaxAndMinNoteInterval())\t")
//            print("Mean of Note Interval: \(i.getMeanOfNoteInterval())\t")
//            print("Poosibility of drum: \(i.getDrumPossibility())\t")
//            print("Number of Voices: \(i.getNumOfVoices())\n")
//        }
//        STFileManager.shared.saveCurrentBlock()
        PlaybackEngine.shared.playSequence()
        
    }
    override func viewWillAppear(_ animated: Bool) {
//        musicTable.reloadData()
        self.addChildViewController(appDelegate.playbackController)
        appDelegate.playbackController.view.frame = self.playbackBar.bounds
        self.playbackBar.addSubview(appDelegate.playbackController.view)
        appDelegate.playbackController.didMove(toParentViewController: self)
    }
}
