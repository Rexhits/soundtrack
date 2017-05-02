//
//  ComposeViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/9/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Material
import AVFoundation

class ComposeViewController: UIViewController {
    
    var rootVC: PagingViewController!
    var playBtn: FABButton!
    @IBOutlet weak var touchBar: UIControl!
    @IBOutlet weak var mainCollectionView: UICollectionView!
    
    @IBOutlet weak var secondCollectionView: UICollectionView!
    var buildingBlocks:[Clip]!
    var clipsOnTrack: [Clip]!
    var piece: Piece!
    var movingIndexPath: IndexPath!
    var pseudoCell: UIView!
    var playing = false
    var blinkingIndex = 0
    var formerLength:Double = 0
    
    override func viewDidLoad() {
        
        playBtn = FABButton(image: Icon.cm.play, tintColor: .white)
        playBtn.setImage(Icon.cm.pause, for: .selected)
        playBtn.backgroundColor = UIColor.hexStringToUIColor(hex: "#46b9be")
        playBtn.pulseColor = UIColor.white
        playBtn.addTarget(self, action: #selector(playBtn(_:)), for: .touchUpInside)
        view.addSubview(playBtn)
        view.layout(playBtn).bottom(8).centerHorizontally().size(CGSize(width: 60, height: 60))
        pseudoCell = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        self.view.addSubview(pseudoCell)
        pseudoCell.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        PlaybackEngine.shared.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.piece = rootVC.piece
        buildingBlocks = piece.hasClips!.map{$0 as! Clip}.filter{$0.userComposed}
        clipsOnTrack = piece.hasClips!.map{$0 as! Clip}.filter{$0.beingUsed}.sorted{$0.0.index < $0.1.index}
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture(gesture:)))
        let longGesture2 = UILongPressGestureRecognizer(target: self, action: #selector(handleLongGesture2(gesture:)))
        self.mainCollectionView.addGestureRecognizer(longGesture)
        self.secondCollectionView.addGestureRecognizer(longGesture2)
        mainCollectionView.delegate = self
        secondCollectionView.delegate = self
        mainCollectionView.dataSource = self
        secondCollectionView.dataSource = self
        mainCollectionView.reloadData()
        secondCollectionView.reloadData()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        PlaybackEngine.shared.delegate = nil
    }
    @IBAction func playBtn(_ sender: FABButton) {
        guard !self.clipsOnTrack.isEmpty else {
            return
        }
        if !sender.isSelected {
            sender.isSelected = true
            let block = concatenateData()
            let clip = Clip(length: block.getBlockLength(), data: block.getSequenceData()! as NSData, fromMainBlock: nil)
            clip.timeSignature = "\(block.timeSignature.lengthPerBeat)/\(block.timeSignature.beatsPerMeasure)"
            piece.finishedClip = clip
            appDelegate.saveContext()
            PlaybackEngine.shared.updateBlock(newBlock: block)
            PlaybackEngine.shared.playSequence()
            playing = true
            for i in mainCollectionView.visibleCells {
                i.alpha = 0.1
            }
        } else {
            sender.isSelected = false
            PlaybackEngine.shared.stopSequence()
            playing = false
            for i in mainCollectionView.visibleCells {
                i.alpha = 1
            }
        }
    }
    
    func concatenateData() -> MusicBlock{
        let newblock = MusicBlock(clip: clipsOnTrack.first!)
        var length: Double = 0
        for i in clipsOnTrack {
            let block = MusicBlock(clip: i)
            for n in 0 ..< block.parsedTracks.count {
                for var note in block.parsedTracks[n].notes {
                    note.timeStamp += length
                    newblock.addNoteEvent(trackNum: n, note: note)
                }
            }
            length += ceil(i.length)
        }
        return newblock
    }
    
}

extension ComposeViewController {
    
    
    func handleLongGesture(gesture: UILongPressGestureRecognizer) {
        let globalPosition = gesture.location(in: view)
        guard mainCollectionView.frame.contains(globalPosition) else {
            mainCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
            pseudoCell.backgroundColor = UIColor.hexStringToUIColor(hex: "#ff5079").withAlphaComponent(0.8)
            pseudoCell.center = globalPosition
            pseudoCell.isHidden = false
            if gesture.state == .ended {
                mainCollectionView.cancelInteractiveMovement()
                pseudoCell.isHidden = true
                if secondCollectionView.frame.contains(globalPosition) {
                    clipsOnTrack[movingIndexPath.row].beingUsed = false
                    clipsOnTrack.remove(at: movingIndexPath.row)
                    mainCollectionView.deleteItems(at: [movingIndexPath])
                    appDelegate.saveContext()
                    secondCollectionView.indexPathsForSelectedItems?.forEach{secondCollectionView.deselectItem(at: $0, animated: true)}
                    mainCollectionView.indexPathsForSelectedItems?.forEach{secondCollectionView.deselectItem(at: $0, animated: true)}
                }
                
            }
            return
        }
        switch gesture.state {
        case .began:
            guard let selectedIndexPath = self.mainCollectionView.indexPathForItem(at: gesture.location(in: self.mainCollectionView)) else {
                return
            }
            self.movingIndexPath = selectedIndexPath
            mainCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            pseudoCell.isHidden = true
            mainCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            appDelegate.saveContext()
            mainCollectionView.endInteractiveMovement()
        default:
            mainCollectionView.cancelInteractiveMovement()
        }
    }
    
    func handleLongGesture2(gesture: UILongPressGestureRecognizer) {
        let globalPosition = gesture.location(in: view)
        guard secondCollectionView.frame.contains(globalPosition) else {
            secondCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
            pseudoCell.backgroundColor = Color.blue.base.withAlphaComponent(0.8)
            pseudoCell.center = globalPosition
            pseudoCell.isHidden = false
            if gesture.state == .ended {
                secondCollectionView.cancelInteractiveMovement()
                pseudoCell.isHidden = true
                if mainCollectionView.frame.contains(globalPosition) {
                    clipsOnTrack.append(buildingBlocks[movingIndexPath.row])
                    clipsOnTrack.last?.beingUsed = true
                    clipsOnTrack.last?.index = Int16(movingIndexPath.row)
                    let indexPath = IndexPath(row: clipsOnTrack.count - 1, section: 0)
                    mainCollectionView.insertItems(at: [indexPath])
                    appDelegate.saveContext()
                    secondCollectionView.indexPathsForSelectedItems?.forEach{secondCollectionView.deselectItem(at: $0, animated: true)}
                    mainCollectionView.indexPathsForSelectedItems?.forEach{secondCollectionView.deselectItem(at: $0, animated: true)}
                }
            }
            return
        }
        switch gesture.state {
        case .began:
            guard let selectedIndexPath = self.secondCollectionView.indexPathForItem(at: gesture.location(in: self.secondCollectionView)) else {
                return
            }
            self.movingIndexPath = selectedIndexPath
            secondCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            pseudoCell.isHidden = true
            secondCollectionView.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
        case .ended:
            appDelegate.saveContext()
            secondCollectionView.endInteractiveMovement()
        default:
            secondCollectionView.cancelInteractiveMovement()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if collectionView == mainCollectionView {
            let temp = clipsOnTrack[sourceIndexPath.row]
            temp.index = Int16(destinationIndexPath.row)
            clipsOnTrack[sourceIndexPath.row] = clipsOnTrack[destinationIndexPath.row]
            clipsOnTrack[destinationIndexPath.row] = temp
        } else {
            let temp = buildingBlocks[sourceIndexPath.row]
            buildingBlocks[sourceIndexPath.row] = buildingBlocks[destinationIndexPath.row]
            buildingBlocks[destinationIndexPath.row] = temp
        }
    }
    
}

extension ComposeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == mainCollectionView {
            return clipsOnTrack.count
        } else {
            return buildingBlocks.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell: UICollectionViewCell!
        if collectionView == mainCollectionView {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "composeCell", for: indexPath)
            cell.backgroundColor = UIColor.hexStringToUIColor(hex: "#ff5079")
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: "clipCell", for: indexPath)
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "composeHeader", for: indexPath) as! ClipsHeader
            view.title.text = "Clips in Piece"
            view.backgroundColor = UIColor.hexStringToUIColor(hex: "#46b9be")
            return view
        } else {
            assert(false, "Unexpected element kind")
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print(indexPath.row)
        if collectionView == secondCollectionView {
            if PlaybackEngine.shared.isPlaying {
                collectionView.deselectItem(at: indexPath, animated: true)
                PlaybackEngine.shared.stopSequence()
            } else {
                let block = MusicBlock(clip: buildingBlocks[indexPath.row])
                PlaybackEngine.shared.updateBlock(newBlock: block)
                PlaybackEngine.shared.playSequence()
            }
        } else {
            
        }
        
    }
}

extension ComposeViewController: PlaybackEngineDelegate {
    func updateTime(currentTime: AVMusicTimeStamp) {
        guard PlaybackEngine.shared.isPlaying else {
            return
        }
        DispatchQueue.main.async {
            guard self.playing else {return}
            guard self.blinkingIndex < self.clipsOnTrack.count else {return}
            var scale = (currentTime - self.formerLength) / self.clipsOnTrack[self.blinkingIndex].length
            if scale > 1 {
                self.formerLength += self.clipsOnTrack[self.blinkingIndex].length
                self.blinkingIndex += 1
                guard self.blinkingIndex < self.clipsOnTrack.count else {return}
                scale = (currentTime - self.formerLength) / self.clipsOnTrack[self.blinkingIndex].length
            }
            let indexPath = IndexPath(row: self.blinkingIndex, section: 0)
            self.mainCollectionView.cellForItem(at: indexPath)?.isSelected = true
            self.mainCollectionView.cellForItem(at: indexPath)?.alpha = CGFloat(scale)

        }
        
    }
    
    func didLoadBlock(block: MusicBlock) {
        //
    }
    func didFinishLoop() {
        //
        
    }
    func didStartLoop() {
        //
    }
    func didStartPlaying() {
        //
        
    }
    func didFinishPlaying() {
        //
        
        DispatchQueue.main.async {
            self.blinkingIndex = 0
            self.formerLength = 0
            self.playing = false
            for i in self.mainCollectionView.visibleCells {
                i.isSelected = false
                i.alpha = 1
            }
            for i in self.secondCollectionView.visibleCells {
                i.isSelected = false
            }
            self.playBtn.isSelected = false
        }
    }
}
