//
//  BillboardViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 3/29/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Material
import SwiftyJSON
import AVFoundation
import CoreData
import HDAugmentedReality

class BillboardViewController: UIViewController, BillboardCellDelegate, UICollectionViewDelegate {
    
    
    
    var selectedBillboard: BillboardSerializer!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var audioPlayer: AVPlayer!
    
    var blocksOnBoard: [MusicBlockSerializer]!
    
    var piecesOnBoard: [PieceSerializer]!
    
    var selectedBlock: BillboardCellView?
    
    var blockDataSource: BlockOnBoardDataSource!
    
    var pieceDataSource: PiecesOnBoardDataSource!
    
    override func viewDidLoad() {
        blockDataSource = BlockOnBoardDataSource(viewController: self)
        pieceDataSource = PiecesOnBoardDataSource(viewController: self)
        collectionView.delegate = self
    }
    
    @IBOutlet weak var pageControl: UISegmentedControl!
    
    override func viewWillAppear(_ animated: Bool) {
        self.blocksOnBoard = [MusicBlockSerializer]()
        self.piecesOnBoard = [PieceSerializer]()
        collectionView.dataSource = blockDataSource
//        self.collectionView.reloadData()
        fetch()
    }
    
    @IBAction func pageChanged(_ sender: UISegmentedControl) {
        self.selectedBlock = nil
        for i in collectionView.visibleCells {
            let cell = i as! BillboardCellView
            cell.playStopBtn.isSelected = false
            self.audioPlayer = nil
        }
        if sender.selectedSegmentIndex == 0 {
            collectionView.dataSource = blockDataSource
        } else {
            collectionView.dataSource = pieceDataSource
        }
        collectionView.reloadData()
    }
    
    func fetch() {
        if let billboard = self.selectedBillboard {
            ServerCommunicator.shared.get(url: billboard.url!, body: nil, completion: { (response, err, errCode) in
                guard response != nil else {return}
                let json = JSON(response!)
                let blocks = json["blockOnBoard"]
                for i in blocks {
                    self.blocksOnBoard.append(MusicBlockSerializer(json: i.1))
                }
                let pieces = json["pieceOnBoard"]
                for i in pieces {
                    self.piecesOnBoard.append(PieceSerializer(json: i.1))
                }
                self.collectionView.reloadData()
            })
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.audioPlayer != nil {
            self.audioPlayer.pause()
            self.audioPlayer = nil
        }
        self.selectedBlock = nil
        for i in collectionView.visibleCells {
            if let cell = i as? BillboardCellView {
                cell.playStopBtn.isSelected = false
            }
        }
    }
    
    func playTapped(sender: BillboardCellView) {
        PlaybackEngine.shared.stopSequence()
        print("play tapped")
        guard pageControl.selectedSegmentIndex == 0 else {
            if let url = sender.piece.audioUrl {
                if self.selectedBlock == nil {
                    audioPlayer = AVPlayer(url: URL(string: url)!)
                    audioPlayer.play()
                    self.selectedBlock = sender
                } else if sender != self.selectedBlock! {
                    selectedBlock!.playStopBtn.isSelected = false
                    audioPlayer = AVPlayer(url: URL(string: url)!)
                    audioPlayer.play()
                    self.selectedBlock = sender
                } else {
                    audioPlayer.play()
                }
            }
            return
        }
        if let url = sender.block.audioUrl {
            if self.selectedBlock == nil {
                audioPlayer = AVPlayer(url: URL(string: url)!)
                audioPlayer.play()
                self.selectedBlock = sender
            } else if sender != self.selectedBlock! {
                selectedBlock!.playStopBtn.isSelected = false
                audioPlayer = AVPlayer(url: URL(string: url)!)
                audioPlayer.play()
                self.selectedBlock = sender
            } else {
                audioPlayer.play()
            }
        }
    }
    
    
    
    func stopTapped(sender: BillboardCellView) {
        print("stop tapped")
        audioPlayer.pause()
    }
    
    func liked(sender: BillboardCellView) {
        print("like tapped")
        guard pageControl.selectedSegmentIndex == 0 else {
            if let url = sender.piece.url {
                ServerCommunicator.shared.get(url: url + "like/", body: nil, completion: { (response, err, errCode) in
                })
            }
            return
        }
        if let url = sender.block.url {
            ServerCommunicator.shared.get(url: url + "like/", body: nil, completion: { (response, err, errCode) in
            })
        }
    }
    
    func disLiked(sender: BillboardCellView) {
        print("dislike tapped")
        guard pageControl.selectedSegmentIndex == 0 else {
            if let url = sender.piece.url {
                ServerCommunicator.shared.get(url: url + "dislike/", body: nil, completion: { (response, err, errCode) in
                })
            }
            return
        }
        if let url = sender.block.url {
            ServerCommunicator.shared.get(url: url + "dislike/", body: nil, completion: { (response, err, errCode) in
            })
        }
        
    }
    func shareTapped(sender: BillboardCellView) {
        //
    }
}

class BlockOnBoardDataSource: NSObject, UICollectionViewDataSource {

    var vc: BillboardViewController!
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vc.blocksOnBoard.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "billboardCell", for: indexPath) as! BillboardCellView
        cell.block = vc.blocksOnBoard[indexPath.row]
        cell.delegate = vc
        if let saved = vc.blocksOnBoard[indexPath.row].saved {
            if saved {
                cell.likeBtn.isSelected = true
                cell.likeBtn.tintColor = UIColor.red
            } else {
                cell.likeBtn.isSelected = false
                cell.likeBtn.tintColor = UIColor.lightGray
            }
        }
        return cell
    }
    
    convenience init(viewController: BillboardViewController) {
        self.init()
        self.vc = viewController
    }
}

class PiecesOnBoardDataSource: NSObject, UICollectionViewDataSource {
    
    var vc: BillboardViewController!
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vc.piecesOnBoard.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "billboardCell", for: indexPath) as! BillboardCellView
        cell.piece = vc.piecesOnBoard[indexPath.row]
        cell.delegate = vc
        if vc.piecesOnBoard[indexPath.row].saved {
            cell.likeBtn.isSelected = true
            cell.likeBtn.tintColor = UIColor.red
        } else {
            cell.likeBtn.isSelected = false
            cell.likeBtn.tintColor = UIColor.lightGray
        }
        return cell
    }
    
    convenience init(viewController: BillboardViewController) {
        self.init()
        self.vc = viewController
    }
}


class BillboardCellView: UICollectionViewCell {
    var delegate: BillboardCellDelegate?
    var block: MusicBlockSerializer! {
        didSet {
            self.artist.text = block.composedBy?.name
            self.title.text = block.title
            self.date.text = block.date
            if let avatar = block.composedBy?.avatar {
                self.avatar.image = UIImage(data: avatar as Data)
            }
        }
    }
    var piece: PieceSerializer! {
        didSet {
            self.artist.text = piece.composedBy?.name
            self.title.text = piece.title
            self.date.text = piece.date
            if let avatar = piece.composedBy?.avatar {
                self.avatar.image = UIImage(data: avatar as Data)
            }
        }
    }
    var indexPath: IndexPath?
    @IBOutlet weak var artist: UILabel!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var playStopBtn: UIButton!
    @IBOutlet weak var likeBtn: UIButton!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var avatar: UIImageView!
    var avatarData: Data? {
        didSet {
            if let data = avatarData {
                self.avatar.image = UIImage(data: data)
            }
        }
    }
    var shareBtnIcon: UIImage? = Icon.share?.withRenderingMode(.alwaysTemplate)
    
    override func layoutSubviews() {
        
        self.playStopBtn.setBackgroundImage(Icon.cm.play?.withRenderingMode(.alwaysTemplate), for: .normal)
        self.playStopBtn.setBackgroundImage(Icon.cm.pause?.withRenderingMode(.alwaysTemplate), for: .selected)
        self.shareBtn.setImage(shareBtnIcon, for: .normal)
        self.likeBtn.setImage(Icon.favorite?.withRenderingMode(.alwaysTemplate), for: .normal)
        let radius = self.playStopBtn.frame.size.height / 2
        self.playStopBtn.layer.cornerRadius = radius
        self.playStopBtn.layer.borderWidth = 2.5
        self.playStopBtn.layer.borderColor = UIColor.orange.cgColor
        let avatarRadius = self.avatar.frame.size.height / 2
        self.avatar.layer.cornerRadius = avatarRadius
        self.avatar.layer.masksToBounds = false
        self.avatar.clipsToBounds = true
    }
    
    
    
    @IBAction func playStopBtnTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            if self.playStopBtn.isSelected {
                self.delegate?.stopTapped(sender: self)
                self.playStopBtn.isSelected = false
            } else {
                self.delegate?.playTapped(sender: self)
                self.playStopBtn.isSelected = true
            }
        }
    }
    @IBAction func likeBtnTapped(_ sender: UIButton) {
        DispatchQueue.main.async {
            if self.likeBtn.isSelected {
                self.delegate?.disLiked(sender: self)
                self.likeBtn.isSelected = false
                self.likeBtn.tintColor = UIColor.lightGray
            } else {
                self.delegate?.liked(sender: self)
                self.likeBtn.isSelected = true
                self.likeBtn.tintColor = UIColor.red
            }
        }
    }
    @IBAction func shareBtnTapped(_ sender: UIButton) {
        self.delegate?.shareTapped(sender: self)
    }
    
    
}





protocol BillboardCellDelegate {
    func playTapped(sender: BillboardCellView)
    func stopTapped(sender: BillboardCellView)
    func liked(sender: BillboardCellView)
    func disLiked(sender: BillboardCellView)
    func shareTapped(sender: BillboardCellView)
}
