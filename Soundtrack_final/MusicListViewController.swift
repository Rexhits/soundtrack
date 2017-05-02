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
import Persei
import AVFoundation
import PopupDialog

class MusicListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MusicBlockSerializerDelegate, ServerCommunicatorDelegate {
    
    internal func editBtnTouched(indexPath: IndexPath) {
        if indexPath.section == 0 {
            self.performSegue(withIdentifier: "gotoBlockInfoEditor", sender: indexPath)
        } else {
            self.performSegue(withIdentifier: "gotoUploadPage", sender: indexPath)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoUploadPage" {
            if let indexPath = sender as? IndexPath {
                let des = segue.destination as! BlockUploadViewController
                des.uploadingBlock = false
                des.mp3URL = newContentDataSource.pieces[indexPath.row]
            }
        }
    }

    @IBOutlet weak var playbackBar: UIView!
    
    @IBOutlet weak var musicTable: UITableView!
    
    var audioPlayer: AVPlayer!
    
    let menu = MenuView()
//    var musicList = [MusicBlock]()
    var selectedIndexPath: IndexPath!
    var blockDataSource: BlockDataSource!
    var pieceDataSource: PieceDataSource!
    var newContentDataSource: NewContentDataSource!
    func userFetched() {
        blockDataSource.fetch()
        pieceDataSource.fetch()
        newContentDataSource.fetch()
        musicTable.reloadData()
    }
    
    override func viewDidLoad() {
        
        blockDataSource = BlockDataSource(viewController: self)
        pieceDataSource = PieceDataSource(viewController: self)
        newContentDataSource = NewContentDataSource(viewController: self)
        musicTable.delegate = pieceDataSource
        musicTable.dataSource = pieceDataSource
//        let files = Bundle.main.paths(forResourcesOfType: "mid", inDirectory: nil)
//        for i in files {
//            if let url = URL.init(string: i) {
//                musicList.append(MusicBlock(name: url.fileName(), composedBy: "zzw", midiFile: url))
//            }
//        }
        ServerCommunicator.shared.delegate = self
        let blockIcon = MenuItem(image: Icon.cm.audio!)
        let pieceIcon = MenuItem(image: Icon.cm.audioLibrary!)
        let importedIcon = MenuItem(image: Icon.work!)
        menu.items = [blockIcon, pieceIcon, importedIcon]
        menu.contentHeight = 100
        
        
        musicTable.addSubview(menu)
        menu.delegate = self
        musicTable.backgroundColor = UIColor.clear
        self.view.backgroundColor = UIColor.gray
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Collected Blocks"
        } else {
            return "Composed Blocks"
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            view.backgroundColor = UIColor.clear
            view.contentView.backgroundColor = UIColor.clear
            view.textLabel?.textColor = UIColor.darkText
            view.textLabel?.font = view.textLabel?.font.withSize(12)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if let collected = currentUser?.collectedBlocks {
                return collected.count
            } else {
                return 0
            }
        default:
            if let composed = currentUser?.composedBlocks {
                return composed.count
            } else {
                return 0
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = musicTable.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath) as! MusicListCell
//        cell.delegate = self
        cell.editBtn.isHidden = true
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = currentUser!.collectedBlocks![indexPath.row].title
            if let composer = currentUser!.collectedBlocks?[indexPath.row].composedBy {
                cell.editBtn.removeFromSuperview()
                cell.detailTextLabel?.text = ""
                guard composer.avatar != nil else {return cell}
                cell.imageView?.image = UIImage(data: composer.avatar! as Data)
            }
            
        default:
            cell.textLabel?.text = currentUser!.composedBlocks![indexPath.row].title
        }
        
        return cell
    }
    
    func blockConfigured(block: MusicBlock) {
//        DispatchQueue.main.async {
//            self.musicList.append(block)
//            self.musicTable.reloadData()
//        }
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        let cell = tableView.cellForRow(at: indexPath)! as! MusicListCell
        cell.editBtn.isHidden = false
        if selectedIndexPath != indexPath {
//            PlaybackEngine.shared.addMusicBlock(musicBlock: musicList[indexPath.row])
        }
        
        selectedIndexPath = indexPath
        
        
//        musicList[indexPath.row].trainClassifier()
        
//        STFileManager.shared.saveCurrentBlock()
        
//        musicList[indexPath.row].uploadToServer()
        
        
//        musicList[indexPath.row].saveJson()
        
//        for i in musicList[indexPath.row].parsedTracks {
        
//            print("\(i.groupAnalysis())\n")
//            print("\(i.tempo)\t\(i.timeSignature)\t\(i.instrumentName)")
//            print("\(i.notes.map{$0.timeStamp})\n")
//            i.byMeasure()
            
//            print(i.getMeanNoteLength())
//            print("\(i.byMeasure().map{$0.notes.map({$0.timeStamp})})\n")
//            print("\(i.instrumentName): \(i.byMeasure().map{$0.getNoteDistribution()})\n")
//        }
        
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
    

    override func viewWillAppear(_ animated: Bool) {
        ServerCommunicator.shared.getCurrentUser()
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
    var indexPath: IndexPath!
    func gotoEdit(sender: UIButton) {
        if delegate != nil {
            delegate.editBtnTouched(indexPath: indexPath)
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
        self.detailTextLabel?.textColor = UIColor.white
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

class BlockDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    var artists = [ComposerSerializer]()
    var blocks = [[MusicBlockSerializer]]()
    var vc: MusicListViewController!
    func numberOfSections(in tableView: UITableView) -> Int {
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blocks[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = vc.musicTable.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath) as! MusicListCell
        cell.editBtn.isHidden = true
        cell.textLabel?.text = blocks[indexPath.section][indexPath.row].title
        cell.detailTextLabel?.text = ""
        return cell
    }
    
    convenience init(viewController: MusicListViewController) {
        self.init()
        self.vc = viewController
    }
    
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            let imageView = UIImageView(image: UIImage(data: artists[section].avatar! as Data)?.resize(x: 60, y: 60))
            view.contentView.addSubview(imageView)
            view.layout(imageView).left()
            let label = UILabel()
            label.textColor = UIColor.white
            label.text = artists[section].name
            view.contentView.addSubview(label)
            view.layout(label).left(80).centerVertically()
            view.contentView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
            guard artists[section].avatar != nil else {
                label.text = "You haven't collected or composed anything yet..."
                return
            }
            
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url = blocks[indexPath.section][indexPath.row].audioUrl else {
            return
        }
        PlaybackEngine.shared.stopSequence()
        vc.audioPlayer = AVPlayer(url: URL(string: url)!)
        vc.audioPlayer.play()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func fetch() {
        var all = [MusicBlockSerializer]()
        if let musicList = currentUser?.collectedBlocks{
            all.append(contentsOf: musicList)
        }
        if let composed = currentUser?.composedBlocks {
            all.append(contentsOf: composed)
        }
        let allSet = Set<MusicBlockSerializer>(all.map{$0})
        let artistList = Set<ComposerSerializer>(allSet.map{$0.composedBy!})
        artists = artistList.map{$0}.sorted{$0.0.name! < $0.1.name!}
        for i in 0 ..< artists.count {
            if artists[i].id == currentUser?.id {
                let user = artists[i]
                artists.remove(at: i)
                artists.insert(user, at: 0)
            }
        }
        blocks = artists.map({ (composer) -> [MusicBlockSerializer] in
            return allSet.filter{$0.composedBy == composer}.sorted{$0.0.title! < $0.1.title!}
        })
    }
    
}

class PieceDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    var artists = [ComposerSerializer]()
    var pieces = [[PieceSerializer]]()
    var vc: MusicListViewController!
    func numberOfSections(in tableView: UITableView) -> Int {
        return artists.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pieces[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = vc.musicTable.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath) as! MusicListCell
//        cell.editBtn.removeFromSuperview()
        cell.editBtn.isHidden = true
        cell.textLabel?.text = pieces[indexPath.section][indexPath.row].title
        cell.detailTextLabel?.text = ""
        return cell
    }
    
    convenience init(viewController: MusicListViewController) {
        self.init()
        self.vc = viewController
    }
    
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let view = view as? UITableViewHeaderFooterView {
            let imageView = UIImageView(image: UIImage(data: artists[section].avatar! as Data)?.resize(x: 60, y: 60))
            view.contentView.addSubview(imageView)
            view.layout(imageView).left()
            let label = UILabel()
            label.textColor = UIColor.white
            label.text = artists[section].name
            view.contentView.addSubview(label)
            view.layout(label).left(80).centerVertically()
            view.contentView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
            guard artists[section].avatar != nil else {
                label.text = "You haven't collected or composed anything yet..."
                return
            }
            
            
        }
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    func fetch() {
        var all = [PieceSerializer]()
        if let musicList = currentUser?.collectedPieces{
            all.append(contentsOf: musicList)
        }
        if let composed = currentUser?.composedPieces {
            all.append(contentsOf: composed)
        }
        let allSet = Set<PieceSerializer>(all.map{$0})
        let artistList = Set<ComposerSerializer>(allSet.map{$0.composedBy!})
        artists = artistList.map{$0}.sorted{$0.0.name! < $0.1.name!}
        for i in 0 ..< artists.count {
            if artists[i].id == currentUser?.id {
                let user = artists[i]
                artists.remove(at: i)
                artists.insert(user, at: 0)
            }
        }
        pieces = artists.map({ (composer) -> [PieceSerializer] in
            return allSet.filter{$0.composedBy == composer}.sorted{$0.0.title! < $0.1.title!}
        })
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let url =  pieces[indexPath.section][indexPath.row].audioUrl else {
            return
        }
        PlaybackEngine.shared.stopSequence()
        vc.audioPlayer = AVPlayer(url: URL(string: url)!)
        vc.audioPlayer.play()
    }
    
}

class NewContentDataSource: NSObject, UITableViewDataSource, UITableViewDelegate, MusicListCellDelegate {
    
    func editBtnTouched(indexPath: IndexPath) {
        vc.editBtnTouched(indexPath: indexPath)
    }

    
    var musicBlocks = [URL]()
    var pieces = [URL]()
    var vc: MusicListViewController!
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if !musicBlocks.isEmpty {
                return musicBlocks.count
            } else {
                return 0
            }
        } else {
            if !pieces.isEmpty {
                return pieces.count
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = vc.musicTable.dequeueReusableCell(withIdentifier: "musicCell", for: indexPath) as! MusicListCell
        cell.delegate = self
        cell.editBtn.isHidden = true
        if indexPath.section == 0 {
            cell.textLabel?.text = musicBlocks[indexPath.row].lastPathComponent
        } else {
            cell.textLabel?.text = pieces[indexPath.row].lastPathComponent
        }
        
        cell.detailTextLabel?.text = ""
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//        let rename = UITableViewRowAction(style: .default, title: "Rename") { (_, indexPath) in
//            let popview = UIAlertController(title: "Rename", message: nil, preferredStyle: .alert)
//            popview.addTextField(configurationHandler: { (textField) in
//                textField.placeholder = "Enter New Name Here..."
//            })
//            let ok = UIAlertAction(title: "OK", style: .default, handler: { (_) in
//                guard !popview.textFields!.first!.text!.isEmpty else {
//                    return
//                }
//                var folder = getURLInDocumentDirectoryWithFilename(filename: "Inbox")
//                folder.appendPathComponent(popview.textFields!.first!.text!)
//                if indexPath.section == 0 {
//                    folder.appendPathExtension("mid")
//                    do {
//                        try FileManager.default.moveItem(at: self.musicBlocks![indexPath.row], to: folder)
//                    } catch {
//                        print(error.localizedDescription)
//                    }
//                } else {
//                    folder.appendPathExtension("mp3")
//                    do {
//                        try FileManager.default.moveItem(at: self.pieces![indexPath.row], to: folder)
//                    } catch {
//                        print(error.localizedDescription)
//                    }
//                }
//            })
//            let cancel = UIAlertAction(title: "cancel", style: .default, handler: nil)
//            popview.addAction(ok)
//            popview.addAction(cancel)
//            self.vc.present(popview, animated: true, completion: {
//                self.vc.musicTable.reloadData()
//            })
//        }

        
        let delete = UITableViewRowAction(style: .destructive, title: "Remove") { (action, indexPath) in
            let popView = PopupDialog(title: "Are You Sure to Delete it?", message: nil)
            let yes = DefaultButton(title: "Yes", action: {
                if indexPath.section == 0 {
                    do {
                        try FileManager.default.removeItem(at: self.musicBlocks[indexPath.row])
                    } catch {
                        print(error.localizedDescription)
                    }
                    self.vc.musicTable.reloadData()
                } else {
                    do {
                        try FileManager.default.removeItem(at: self.pieces[indexPath.row])
                    } catch {
                        print(error.localizedDescription)
                    }
                    self.vc.musicTable.reloadData()
                    
                }
            })
            let cancel = DefaultButton(title: "Cancel", action: nil)
            popView.addButtons([yes, cancel])
            self.vc.present(popView, animated: true, completion: nil)
        }
        return [delete]
    }
    
    convenience init(viewController: MusicListViewController) {
        self.init()
        self.vc = viewController
    }
    
    func fetch() {
        let inBox = getURLInDocumentDirectoryWithFilename(filename: "Inbox")
        do {
            let files = try FileManager.default.contentsOfDirectory(at: inBox, includingPropertiesForKeys: nil, options: [])
            musicBlocks = files.filter{$0.pathExtension == "mid"}
            pieces = files.filter{$0.pathExtension == "mp3"}
        } catch let err as NSError {
            print(err.localizedDescription)
        }

    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UITableViewHeaderFooterView()
        view.contentView.backgroundColor = UIColor.darkGray.withAlphaComponent(0.8)
        let label = UILabel()
        label.textColor = UIColor.white
        view.contentView.addSubview(label)
        view.layout(label).left().centerVertically()
        if section == 0 {
            label.text = "Found \(musicBlocks.count) Musicblock(s)"
        } else {
            label.text = "Found \(pieces.count) Piece(s)"
        }
        return view
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlaybackEngine.shared.stopSequence()
        let cell = vc.musicTable.cellForRow(at: indexPath) as! MusicListCell
        cell.indexPath = indexPath
        cell.editBtn.isHidden = false
        if indexPath.section == 0 {
            vc.audioPlayer = nil
            let block = MusicBlock(name: musicBlocks[indexPath.row].fileName(), composedBy: currentUser!.username!, midiFile: musicBlocks[indexPath.row])
            PlaybackEngine.shared.addMusicBlock(musicBlock: block)
            PlaybackEngine.shared.playSequence()
        } else {
            vc.audioPlayer = AVPlayer(url: pieces[indexPath.row])
            vc.audioPlayer.play()
        }
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = vc.musicTable.cellForRow(at: indexPath) as! MusicListCell
        cell.editBtn.isHidden = true
    }
}

extension MusicListViewController: MenuViewDelegate {
    func menu(_ menu: MenuView, didSelectItemAt index: Int) {
        if index == 0 {
            title = "MusicPieces"
            musicTable.delegate = pieceDataSource
            musicTable.dataSource = pieceDataSource
        } else if index == 1{
            title = "MusicBlocks"
            musicTable.delegate = blockDataSource
            musicTable.dataSource = blockDataSource
        } else {
            title = "Imported"
            newContentDataSource.fetch()
            musicTable.delegate = newContentDataSource
            musicTable.dataSource = newContentDataSource
        }
        
        musicTable.reloadData()
    }
}

protocol MusicListCellDelegate {
    func editBtnTouched(indexPath: IndexPath)
}


