//
//  ClipsManagementViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/9/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Material
import AVFoundation
import PopupDialog

class ClipsManagementViewController: UIViewController {
    
    var piece: Piece!
    
    var rootVC: PagingViewController!
    
    var clips: [Clip]!
    
    var composedClips: [Clip]!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var fromMainBtn: RaisedButton!
    
    @IBOutlet weak var fromSecondBtn: RaisedButton!
    
    @IBOutlet weak var editBtn: RaisedButton!
    
    var combineBtn: FABButton!
    
    var deleteBtn: FABButton!
    
    let mainColor = UIColor.hexStringToUIColor(hex: "#ff5079")
    let auxColor = UIColor.hexStringToUIColor(hex: "#5079ff")
    
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        setupButtons()
        self.piece = rootVC.piece
        guard piece.hasClips != nil else {
            return
        }
        self.clips = piece.hasClips!.map{$0 as! Clip}.filter{!$0.userComposed}
        self.composedClips = piece.hasClips!.map{$0 as! Clip}.filter{$0.userComposed}
        collectionView.reloadData()
        PlaybackEngine.shared.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.isEditing = false
        editBtn.isSelected = false
        removeDeleteBtn()
        removeCombineBtn()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "gotoMainBlock" {
            PlaybackEngine.shared.addMusicBlock(musicBlock: rootVC.mainBlock)
            let vc = segue.destination as! TrackSelectorViewController
            vc.block = rootVC.mainBlock
            vc.fromMainBlock = true
            vc.piece = self.piece
            vc.mainBlock = rootVC.mainBlock
        } else if segue.identifier == "gotoSecondBlock" {
            PlaybackEngine.shared.addMusicBlock(musicBlock: rootVC.mainBlock)
            let vc = segue.destination as! TrackSelectorViewController
            guard rootVC.secondBlock != nil else {
                let popup = PopupDialog(title: "Error", message: "Aux Block not found")
                let ok = DefaultButton(title: "OK", action: nil)
                popup.addButton(ok)
                self.present(popup, animated: true, completion: nil)
                return
            }
            vc.fromMainBlock = false
            vc.block = rootVC.secondBlock
            vc.piece = self.piece
            vc.mainBlock = rootVC.mainBlock
        }
    }
    
    
    
}

extension ClipsManagementViewController {
    func setupButtons() {
        fromMainBtn.titleColor = UIColor.white
        fromMainBtn.pulseColor = .white
        fromMainBtn.backgroundColor = mainColor
        fromMainBtn.setImage(Icon.add, for: .normal)
        fromSecondBtn.titleColor = UIColor.white
        fromSecondBtn.pulseColor = .white
        fromSecondBtn.backgroundColor = auxColor
        fromSecondBtn.setImage(Icon.add, for: .normal)
        editBtn.titleColor = UIColor.white
        editBtn.pulseColor = .white
        editBtn.backgroundColor = Color.blue.base
        editBtn.setImage(Icon.edit, for: .normal)
        editBtn.setImage(Icon.close, for: .selected)
        editBtn.setTitle("Edit", for: .normal)
        editBtn.setTitle("Cancel", for: .selected)
        editBtn.addTarget(self, action: #selector(editTapped(sender:)), for: .touchUpInside)
    }
    
    func setupCombineButton() {
        if self.combineBtn == nil {
            combineBtn = FABButton(image: Icon.audio, tintColor: .white)
            combineBtn.pulseColor = UIColor.white
            combineBtn.backgroundColor = UIColor.orange
            combineBtn.setTitle("Combine!", for: .normal)
            combineBtn.titleLabel?.font = combineBtn.titleLabel?.font.withSize(8)
            combineBtn.addTarget(self, action: #selector(combineTapped(sender:)), for: .touchUpInside)
            combineBtn.alpha = 0
            self.view.addSubview(combineBtn)
            self.view.layout(combineBtn).center(offsetX: 0, offsetY: 50).size(CGSize(width: 80, height: 80))
            UIView.animate(withDuration: 0.1, animations: {
                self.combineBtn.alpha = 1.0
            })
        }
    }
    
    func setupDeleteButton() {
        if self.deleteBtn == nil {
            deleteBtn = FABButton(image: Icon.clear, tintColor: .white)
            deleteBtn.pulseColor = UIColor.white
            deleteBtn.backgroundColor = UIColor.blue.withAlphaComponent(0.7)
            deleteBtn.titleLabel?.font = deleteBtn.titleLabel?.font.withSize(8)
            deleteBtn.addTarget(self, action: #selector(deleteTapped(sender:)), for: .touchUpInside)
            deleteBtn.alpha = 0
            self.view.addSubview(deleteBtn)
            self.view.layout(deleteBtn).center().bottom(60).size(CGSize(width: 50, height: 50))
            UIView.animate(withDuration: 0.2, animations: {
                self.deleteBtn.alpha = 1.0
            })
        }
    }
    
    func removeCombineBtn() {
        if combineBtn != nil {
            UIView.animate(withDuration: 0.2, animations: {
                self.combineBtn.alpha = 0
            }, completion: { (_) in
                self.combineBtn!.removeFromSuperview()
                self.combineBtn = nil
            })
            
        }
    }
    
    func removeDeleteBtn() {
        if self.deleteBtn != nil {
            UIView.animate(withDuration: 0.2, animations: {
                self.deleteBtn.alpha = 0
            }, completion: { (_) in
                self.deleteBtn!.removeFromSuperview()
                self.deleteBtn = nil
            })
        }
    }
    
    func editTapped(sender: RaisedButton) {
        if let selected = collectionView.indexPathsForSelectedItems {
            for i in selected {
                collectionView.deselectItem(at: i, animated: true)
            }
        }
        PlaybackEngine.shared.stopSequence()
        if !sender.isSelected {
            self.isEditing = true
            sender.isSelected = true
            sender.backgroundColor = Color.magenta
            self.collectionView.allowsMultipleSelection = true
        } else {
            self.isEditing = false
            sender.isSelected = false
            sender.backgroundColor = Color.blue.base
            self.collectionView.allowsMultipleSelection = false
            removeCombineBtn()
            removeDeleteBtn()
        }
        
    }
    
    func deleteTapped(sender: FABButton) {
        
        for i in collectionView.indexPathsForSelectedItems! {
            print(i.section, i.row)
            print(clips.count)
            let context = appDelegate.persistentContainer.viewContext
            if i.section == 0 {
                context.delete(clips[i.row])
                appDelegate.saveContext()
                clips.remove(at: i.row)
            } else {
                context.delete(composedClips[i.row])
                appDelegate.saveContext()
                composedClips.remove(at: i.row)
            }
            
        }
        collectionView.deleteItems(at: collectionView.indexPathsForSelectedItems!)
        for i in 0 ..< clips.count {
            collectionView.deselectItem(at: IndexPath(row: i, section: 0), animated: true)
        }
        self.isEditing = false
        editBtn.isSelected = false
        removeDeleteBtn()
        removeCombineBtn()

    }
    
    func combineTapped(sender: FABButton) {
        guard let selected = collectionView.indexPathsForSelectedItems else {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let combineVC = storyboard.instantiateViewController(withIdentifier: "combineVC") as! CombineViewController
        combineVC.piece = self.piece
        combineVC.mainBlock = MusicBlock(clip: clips[selected[0].row])
        combineVC.auxBlock = MusicBlock(clip: clips[selected[1].row])
        combineVC.modalPresentationStyle = .popover
        combineVC.popoverPresentationController?.permittedArrowDirections = .down
        combineVC.popoverPresentationController?.delegate = self
        combineVC.popoverPresentationController?.sourceView = sender
        combineVC.popoverPresentationController?.sourceRect = sender.bounds
        combineVC.preferredContentSize = CGSize(width: view.width, height: view.bounds.height)
        combineVC.delegate = self
        self.present(combineVC, animated: true, completion: nil)
    }
}

extension ClipsManagementViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .fullScreen
    }
    
}

extension ClipsManagementViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return clips.count
        } else {
            return composedClips.count
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clipCell", for: indexPath)
        if indexPath.section == 0 {
            if clips[indexPath.row].fromMainBlock {
                cell.backgroundColor = mainColor.withAlphaComponent(0.8)
            } else {
                cell.backgroundColor = auxColor.withAlphaComponent(0.8)
            }
        } else {
            cell.backgroundColor = Color.blue.base
        }
        if cell.contentView.subviews.isEmpty {
            let label = UILabel()
            label.text = String(indexPath.row)
            label.textColor = UIColor.white
            cell.contentView.addSubview(label)
            cell.contentView.layout(label).center()
        }
        let view = UIView()
        view.backgroundColor = UIColor.red
        cell.selectedBackgroundView = view
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selected = collectionView.indexPathsForSelectedItems?.count
        guard !isEditing else {
            setupDeleteButton()
            if selected == 2 && indexPath.section == 0{
                setupCombineButton()
            } else {
                removeCombineBtn()
            }
            return
        }
        if PlaybackEngine.shared.isPlaying {
            collectionView.deselectItem(at: indexPath, animated: true)
            PlaybackEngine.shared.stopSequence()
        } else {
            if indexPath.section == 0 {
                let block = MusicBlock(clip: clips[indexPath.row])
                PlaybackEngine.shared.addMusicBlock(musicBlock: rootVC.mainBlock)
                PlaybackEngine.shared.updateBlock(newBlock: block)
                PlaybackEngine.shared.playSequence()
            } else {
                let block = MusicBlock(clip: composedClips[indexPath.row])
                PlaybackEngine.shared.addMusicBlock(musicBlock: rootVC.mainBlock)
                PlaybackEngine.shared.updateBlock(newBlock: block)
                PlaybackEngine.shared.playSequence()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let selected = collectionView.indexPathsForSelectedItems?.count
        PlaybackEngine.shared.stopSequence()
        if isEditing {
            if selected == 0 {
                removeDeleteBtn()
            }
            if selected != 2 || indexPath.section == 1 {
                removeCombineBtn()
            } else {
                setupCombineButton()
            }
        }
        
        
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "clipsHeader", for: indexPath) as! ClipsHeader
            if indexPath.section == 0 {
                view.title.text = "Clips from Blocks"
            } else {
                view.title.text = "Composed Clips"
            }
            return view
        } else {
            assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
    
}



extension ClipsManagementViewController: PlaybackEngineDelegate {
    func didStartLoop() {
        //
    }
    func didFinishLoop() {
        //
    }
    func didStartPlaying() {
        //
    }
    func didFinishPlaying() {
        //
        guard self.collectionView.indexPathsForSelectedItems != nil else {
            return
        }
        for i in self.collectionView.indexPathsForSelectedItems! {
            self.collectionView.deselectItem(at: i, animated: true)
        }
    }
    func didLoadBlock(block: MusicBlock) {
        //
    }
    func updateTime(currentTime: AVMusicTimeStamp) {
        //
    }
}

extension ClipsManagementViewController: CombineVCDelegate {
    func clipCreated() {
        self.dismiss(animated: true, completion: nil)
    }
    func willExit() {
        self.dismiss(animated: true, completion: nil)
    }
}

class ClipsHeader: UICollectionReusableView {
    @IBOutlet weak var title: UILabel!
}
