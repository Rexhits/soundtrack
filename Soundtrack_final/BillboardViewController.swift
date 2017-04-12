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

class BillboardViewController: UIViewController, BillboardCellDelegate , UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    var selectedBillboard: BillboardSerializer!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var blocksOnBoard: [MusicBlockSerializer]!
    
    var audioPlayer: AVPlayer!
    
    var selectedBlock: BillboardCellView?
    
    override func viewDidLoad() {
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.blocksOnBoard = [MusicBlockSerializer]()
        self.collectionView.reloadData()
        fetch()
        
    }
    
    func fetch() {
        if let billboard = self.selectedBillboard {
            ServerCommunicator.shared.get(url: billboard.url!, body: nil, completion: { (response, err, errCode) in
                guard response != nil else {return}
                let json = JSON(response!)
                let blocks = json["blockOnBoard"]
                for i in blocks {
                    self.blocksOnBoard.append(MusicBlockSerializer(json: i.1))
                    self.collectionView.reloadData()
                }
            })
        }
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return blocksOnBoard.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "billboardCell", for: indexPath) as! BillboardCellView
        cell.block = blocksOnBoard[indexPath.row]
        cell.delegate = self
        if let saved = blocksOnBoard[indexPath.row].saved {
            cell.likeBtn.isSelected = saved
            cell.likeBtn.tintColor = UIColor.red
        }
        return cell
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
        if let url = sender.block.url {
            ServerCommunicator.shared.get(url: url + "like/", body: nil, completion: { (response, err, errCode) in
            })
        }
    }
    
    func disLiked(sender: BillboardCellView) {
        print("dislike tapped")
        if let url = sender.block.url {
            ServerCommunicator.shared.get(url: url + "dislike/", body: nil, completion: { (response, err, errCode) in
            })
        }
        
    }
    func shareTapped(sender: BillboardCellView) {
        //
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
