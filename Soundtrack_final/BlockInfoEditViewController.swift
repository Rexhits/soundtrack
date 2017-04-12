//
//  BlockInfoEditViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 2/19/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import SwiftyJSON

class BlockInfoEditViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var playControlBar: UIView!
    
    @IBOutlet weak var image: UIImageView!
    
    @IBOutlet weak var table: UITableView!
    
    var piece: Piece?
    
    let pickerView = UIPickerView(frame: CGRect(x: 0, y: 50, width: 260, height: 162))
    
    var dic: [(String,String)]!
    var tracks = PlaybackEngine.shared.loadedBlock!.parsedTracks.map{($0.name!, $0.sequenceType)}
    let track = PlaybackEngine.shared.loadedBlock?.parsedTracks
    var pickerData = [String]()
    
    override func viewDidLoad() {
        table.delegate = self
        table.dataSource = self
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.addChildViewController(appDelegate.playbackController)
        appDelegate.playbackController.view.frame = self.playControlBar.bounds
        self.playControlBar.addSubview(appDelegate.playbackController.view)
        appDelegate.playbackController.didMove(toParentViewController: self)
//        self.playControlBar.layoutIfNeeded()
        dic = [(String,String)]()
        let block = PlaybackEngine.shared.loadedBlock!
        if let p = piece {
            dic.append(("Title", p.title!))
        } else {
            dic.append(("Title", block.name))
        }
        
        dic.append(("Key", Keys[block.key]))
        dic.append(("TimeSignature", block.timeSignature.description))
        dic.append(("Tempo", String(block.tempo)))
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Global"
        } else {
            return "Tracks"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return dic.count
        } else {
            return tracks.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "blockInfoCell", for: indexPath)
        if indexPath.section == 0 {
            cell.textLabel?.text = dic[indexPath.row].0
            cell.detailTextLabel?.text = dic[indexPath.row].1
        } else {
            cell.textLabel?.text = tracks[indexPath.row].0
            cell.detailTextLabel?.text = SequenceType[tracks[indexPath.row].1]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                showTextFieldEditor(indexPath: indexPath)
            default:
                showPickerEditor(indexPath: indexPath)
            }
        } else {
            showTrackEditor(indexPath: indexPath)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    
    
    func showTextFieldEditor(indexPath: IndexPath) {
        let title = "Editing \(self.dic[indexPath.row].0)"
        let alerview = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alerview.addTextField(configurationHandler: { textField in
            textField.placeholder = "Enter New \(self.dic[indexPath.row].0)"
        })
        let canel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: "OK", style: .default) { action in
            if let text = alerview.textFields![0].text, !text.isEmpty {
                self.dic[indexPath.row].1 = text
                self.table.reloadData()
            }
        }
        alerview.addAction(canel)
        alerview.addAction(ok)
        self.present(alerview, animated: true, completion: nil)
    }
    
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    
    
    func showPickerEditor(indexPath: IndexPath) {
        switch indexPath.row {
        case 1:
            pickerData = Keys
        case 2:
            pickerData = TimeSignatures
        default:
            pickerData = Tempo
            pickerView.selectRow(PlaybackEngine.shared.loadedBlock!.tempo - 40, inComponent: 0, animated: false)
        }
        pickerView.reloadAllComponents()
        let title = "Editing \(self.dic[indexPath.row].0)"
        let alerview = UIAlertController(title: title, message: "\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        alerview.view.addSubview(pickerView)
        let canel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: "OK", style: .default) { action in
            self.dic[indexPath.row].1 = self.pickerData[self.pickerView.selectedRow(inComponent: 0)]
            self.updateBlockData()
            self.table.reloadData()
        }
        alerview.addAction(canel)
        alerview.addAction(ok)
        self.present(alerview, animated: true, completion: nil)
    }
    
    func showTrackEditor(indexPath: IndexPath) {
        pickerData = SequenceType
        let alerview = UIAlertController(title: title, message: "Select Type of Track\(indexPath.row+1)\n\n\n\n\n\n\n\n", preferredStyle: .alert)
        alerview.addTextField { textFiled in
            textFiled.placeholder = "Enter Name Of The Track\(indexPath.row+1)"
        }
        alerview.view.addSubview(pickerView)
        let canel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let ok = UIAlertAction(title: "OK", style: .default) { action in
            if !alerview.textFields![0].text!.isEmpty {
                self.tracks[indexPath.row].0 = alerview.textFields![0].text!
                PlaybackEngine.shared.loadedBlock?.parsedTracks[indexPath.row].name = alerview.textFields![0].text!
            }
            self.tracks[indexPath.row].1 = self.pickerView.selectedRow(inComponent: 0)
            PlaybackEngine.shared.loadedBlock?.parsedTracks[indexPath.row].sequenceType = self.pickerView.selectedRow(inComponent: 0)
            self.table.reloadData()
            
        }
        alerview.addAction(canel)
        alerview.addAction(ok)
        self.present(alerview, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        updateBlockData()
        if self.piece != nil {
            self.piece!.title = dic[0].1
            appDelegate.saveContext()
        }
    }
    
    func updateBlockData() {
        if let block = PlaybackEngine.shared.loadedBlock {
            block.name = dic[0].1
            block.key = Keys.index(of: dic[1].1)!
            let timeSig = String(dic[2].1)!.components(separatedBy: "/").map{Int($0)!}
            block.timeSignature = TimeSignature(timeStamp: 0, lengthPerBeat: timeSig.first!, beatsPerMeasure: timeSig.last!)
            block.tempo = Int(dic[3].1)!
            block.addTimeSignatureEvent(timeSignature: block.timeSignature, startAt: 0)
            block.addTempoEvent(bpm: Float64(block.tempo), startAt: 0)
            PlaybackEngine.shared.updateBlock()
        }
    }
    
    
    
}

