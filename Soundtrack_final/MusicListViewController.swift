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
import Material

class MusicListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MusicListCellDelegate, MusicBlockSerializerDelegate {
    
    internal func editBtnTouched() {
        self.performSegue(withIdentifier: "gotoBlockInfoEditor", sender: self)
    }

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
                musicList.append(MusicBlock(name: url.fileName(), composedBy: "zzw", midiFile: url))
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
        let cell = musicTable.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath) as! MusicListCell
        cell.delegate = self
        cell.editBtn.isHidden = true
        cell.textLabel?.text = musicList[indexPath.row].name
        return cell
    }
    
    func blockConfigured(block: MusicBlock) {
        DispatchQueue.main.async {
            self.musicList.append(block)
            self.musicTable.reloadData()
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        let cell = tableView.cellForRow(at: indexPath)! as! MusicListCell
        cell.editBtn.isHidden = false
        if selectedIndexPath != indexPath {
            PlaybackEngine.shared.addMusicBlock(musicBlock: musicList[indexPath.row])
        }
        
        selectedIndexPath = indexPath
        
        
//        musicList[indexPath.row].trainClassifier()
        
//        STFileManager.shared.saveCurrentBlock()
        
//        musicList[indexPath.row].uploadToServer()
        
        
//        musicList[indexPath.row].saveJson()
        
        for i in musicList[indexPath.row].parsedTracks {
            
//            print("\(i.groupAnalysis())\n")
//            print("\(i.tempo)\t\(i.timeSignature)\t\(i.instrumentName)")
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
//        PlaybackEngine.shared.playSequence()
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)! as! MusicListCell
        cell.editBtn.isHidden = true
    }
    
    @IBAction func saveBlock(_ sender: UIBarButtonItem) {
        
    }
    override func viewWillAppear(_ animated: Bool) {
//        musicTable.reloadData()
        self.addChildViewController(appDelegate.playbackController)
        appDelegate.playbackController.view.frame = self.playbackBar.bounds
        self.playbackBar.addSubview(appDelegate.playbackController.view)
        appDelegate.playbackController.didMove(toParentViewController: self)
//        Server.get(api: "users/current", body: nil) { (response, err, errCode) in
//            guard response != nil else {return}
//            let res = JSON(response!)
//            for i in res["savedBlocks"].arrayValue {
//                MusicBlockSerializer.shared.getMusicBlock(json: i)
//            }
//        }
    }
}

class MusicListCell: UITableViewCell {
    
    var delegate: MusicListCellDelegate!
    
    internal func editBtnTouched() {
        
    }
    func gotoEdit(sender: UIButton) {
        if delegate != nil {
            delegate.editBtnTouched()
        }
    }
    
    let editBtn = UIButton(type: UIButtonType.infoDark)
    
    override func awakeFromNib() {
        let width = self.bounds.height - 2
//        let x = self.bounds.width - width - 10
        editBtn.tintColor = UIColor.white
        editBtn.frame = CGRect(x: 0, y: 0, width: width, height: width)
        self.contentView.addSubview(editBtn)
        self.contentView.layout(editBtn).right(15).centerVertically()
        editBtn.addTarget(self, action: #selector(gotoEdit(sender:)), for: .touchUpInside)
        let selView = UIView()
        selView.backgroundColor = UIColor.orange
        selView.layer.cornerRadius = 10
        self.selectedBackgroundView = selView
        self.textLabel?.textColor = UIColor.white
        self.backgroundColor = UIColor.clear
        self.textLabel?.highlightedTextColor = UIColor.white
        self.detailTextLabel?.highlightedTextColor = UIColor.white
    }
    
}


protocol MusicListCellDelegate {
    func editBtnTouched()
}


