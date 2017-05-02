//
//  PieceEditorViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/12/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import SwiftyJSON
import SpriteKit
import Charts
import AVFoundation
import Material
import PopupDialog

class PieceEditorViewController: UIViewController, MusicBlockSerializerDelegate, PopViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, BillboardCellDelegate, PlaybackEngineDelegate {
    func didLoadBlock(block: MusicBlock) {
        //
    }

    func shareTapped(sender: BillboardCellView) {
        //
        if sender.indexPath?.row == 0 {
            self.performSegue(withIdentifier: "showTracks", sender: mainBlock)
        } else if sender.indexPath?.row == 1{
            self.performSegue(withIdentifier: "showTracks", sender: secondBlock)
        } else {
            self.performSegue(withIdentifier: "showTracks", sender: newBlock)
        }
    }

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
        for i in collectionView.visibleCells {
            if let tile = i as? BillboardCellView {
                tile.playStopBtn.isSelected = false
            }
        }
    }
    func updateTime(currentTime: AVMusicTimeStamp) {
        //
    }
    
    func playTapped(sender: BillboardCellView) {
        
        if sender.indexPath?.row == 0 {
            PlaybackEngine.shared.addMusicBlock(musicBlock: self.mainBlock)
            PlaybackEngine.shared.playSequence()
        } else if sender.indexPath?.row == 1{
            PlaybackEngine.shared.addMusicBlock(musicBlock: self.secondBlock)
            PlaybackEngine.shared.playSequence()
        } else {
            PlaybackEngine.shared.addMusicBlock(musicBlock: self.mainBlock)
            PlaybackEngine.shared.updateBlock(newBlock: self.newBlock)
            PlaybackEngine.shared.playSequence()
        }
        
    }
    func liked(sender: BillboardCellView) {
        //
    }
    func disLiked(sender: BillboardCellView) {
        //
    }
    func stopTapped(sender: BillboardCellView) {
        PlaybackEngine.shared.stopSequence()
    }
    
    func blockConfigured(block: MusicBlock) {
        guard mainBlock == nil || secondBlock == nil else {
//            self.collectionView.reloadData()
            return
        }
        if chossingMainBlock {
            self.mainBlock = block
        } else {
            self.secondBlock = block
        }
//        self.collectionView.reloadData()
//        self.performSegue(withIdentifier: "showTracks", sender: block)
    }
    
    @IBOutlet weak var popViewContainer: UIView!
    
    
    var fabButton: FABButton!
    var piece: Piece!
    var scene: Scene!
    var mainBlockItem: FABMenuItem!
    var secondBlockItem: FABMenuItem!
    var composeItem: FABMenuItem!
    let fabMenuSize = CGSize(width: 56, height: 56)
    var fabMenu: FABMenu!
    var mainBlock: MusicBlock!
    var secondBlock: MusicBlock!
    var newBlock: MusicBlock!
    var mainBlockSerializer: MusicBlockSerializer!
    var secondBlockSerializer: MusicBlockSerializer!
    var chossingMainBlock: Bool!
    var popVC: PopViewController!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if let view = self.view as! SKView? {
//            scene = Scene(size: view.frame.size)
//            scene.scaleMode = .resizeFill
//            view.showsPhysics = true
//            view.presentScene(scene)
//        }
        self.view.backgroundColor = UIColor.darkGray
    }
    

    
    
    override func viewWillAppear(_ animated: Bool) {
        fetch()
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        prepareFABButton()
        prepareComposeItem()
        prepareMainBlockItem()
        prepareSecondBlockItem()
        prepareFABMenu()
        PlaybackEngine.shared.delegate = self
        for i in self.childViewControllers {
            if let popVC = i as? PopViewController {
                self.popVC = popVC
            }
        }
        popVC.delegate = self
    }
    
    @IBAction func gotoInfo(_ sender: UIBarButtonItem) {
        if self.newBlock != nil {
            PlaybackEngine.shared.addMusicBlock(musicBlock: self.newBlock)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        PlaybackEngine.shared.delegate = nil
        popVC.delegate = nil
        popVC.removeFromParentViewController()
        fabMenu.removeFromSuperview()
    }
    
    func fetch() {
        if let url = piece.mainBlock {
            ServerCommunicator.shared.get(url: url, body: nil, completion: { (response, err, errCode) in
                guard response != nil else {return}
                self.chossingMainBlock = true
                let json = JSON(response!)
                self.mainBlockSerializer = MusicBlockSerializer(json: json)
                self.mainBlockSerializer.delegate = self
                self.mainBlockSerializer.getMusicBlock(json: json)
                self.collectionView.reloadData()
            })
        }
        if let url = piece.secondBlock {
            ServerCommunicator.shared.get(url: url, body: nil, completion: { (response, err, errCode) in
                guard response != nil else {return}
                self.chossingMainBlock = false
                let json = JSON(response!)
                self.secondBlockSerializer = MusicBlockSerializer(json: json)
                self.secondBlockSerializer.delegate = self
                self.secondBlockSerializer.getMusicBlock(json: json)
                self.collectionView.reloadData()
            })
        }
        
    }
    
    fileprivate func prepareFABButton() {
        fabButton = FABButton(image: Icon.cm.add, tintColor: .white)
        fabButton.pulseColor = .white
        fabButton.backgroundColor = Color.red.base
    }
    
    fileprivate func prepareMainBlockItem() {
        mainBlockItem = FABMenuItem()
        mainBlockItem.title = "MainBlock"
        mainBlockItem.fabButton.image = Icon.cm.audioLibrary
        mainBlockItem.fabButton.tintColor = .white
        mainBlockItem.fabButton.pulseColor = .white
        mainBlockItem.fabButton.backgroundColor = Color.green.base
        mainBlockItem.fabButton.addTarget(self, action: #selector(handleMainBlockItem(button:)), for: .touchUpInside)
    }
    
    fileprivate func prepareSecondBlockItem() {
        secondBlockItem = FABMenuItem()
        secondBlockItem.title = "SecondBlock"
        secondBlockItem.fabButton.image = Icon.cm.audioLibrary
        secondBlockItem.fabButton.tintColor = .white
        secondBlockItem.fabButton.pulseColor = .white
        secondBlockItem.fabButton.backgroundColor = Color.blue.base
        secondBlockItem.fabButton.addTarget(self, action: #selector(handleSecondBlockItem(button:)), for: .touchUpInside)
    }
    
    fileprivate func prepareComposeItem() {
        composeItem = FABMenuItem()
        composeItem.title = "Compose"
        composeItem.fabButton.image = Icon.cm.audio
        composeItem.fabButton.tintColor = .white
        composeItem.fabButton.pulseColor = .white
        composeItem.fabButton.backgroundColor = Color.orange.base
        composeItem.fabButton.addTarget(self, action: #selector(handleComposeItem(button:)), for: .touchUpInside)
    }
    
    fileprivate func prepareFABMenu() {
        fabMenu = FABMenu()
        fabMenu.fabButton = fabButton
        fabMenu.fabMenuItems = [mainBlockItem, secondBlockItem, composeItem]
        fabMenu.fabMenuDirection = .up
        view.layout(fabMenu).size(fabMenuSize).centerHorizontally().bottom(self.view.height * 0.08)
    }
    
    @objc
    fileprivate func handleMainBlockItem(button: UIButton) {
        self.chossingMainBlock = true
        self.fabMenu.isHidden = true
        popViewContainer.isHidden = false
        popVC.pullUp()
        fabMenu.close()
        fabMenu.fabButton?.motion(.rotationAngle(0))
    }
    
    @objc
    fileprivate func handleSecondBlockItem(button: UIButton) {
        self.chossingMainBlock = false
        self.fabMenu.isHidden = true
        popViewContainer.isHidden = false
        popVC.pullUp()
        fabMenu.close()
        fabMenu.fabButton?.motion(.rotationAngle(0))
    }
    
    @objc
    fileprivate func handleComposeItem(button: UIButton) {
        PlaybackEngine.shared.addMusicBlock(musicBlock: self.mainBlock)
        let popup = PopupDialog(title: "Composing Settings", message: "Number of Measures\n\n\n\n")
        
        let items = ["8", "16", "32" , "64"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 1
        popup.view.addSubview(segmentedControl)
        popup.view.layout(segmentedControl).center(offsetX: 0, offsetY: -30)
        let defaultBtn = DefaultButton(title: "Default") {
            let numOfBars = Int(items[segmentedControl.selectedSegmentIndex])
            self.newBlock = self.mainBlock.composeNewContent(numOfBar: numOfBars!, inputBlock: self.secondBlock, step: 0.25, maxMutaitonChance: 0.8)
            self.collectionView.reloadData()
        }
        let softBtn = DefaultButton(title: "Smooth") {
            let numOfBars = Int(items[segmentedControl.selectedSegmentIndex])
            self.newBlock = self.mainBlock.composeNewContent(numOfBar: numOfBars!, inputBlock: self.secondBlock, step: 0.25, maxMutaitonChance: 0.65)
            self.collectionView.reloadData()
        }
        let chaoticBtn = DefaultButton(title: "Chaotic") { 
            let numOfBars = Int(items[segmentedControl.selectedSegmentIndex])
            self.newBlock = self.mainBlock.composeNewContent(numOfBar: numOfBars!, inputBlock: self.secondBlock, step: 0.25, maxMutaitonChance: 1)
            self.collectionView.reloadData()
        }
        
        popup.addButtons([defaultBtn, softBtn, chaoticBtn])
        self.present(popup, animated: true, completion: nil)
        fabMenu.close()
        fabMenu.fabButton?.motion(.rotationAngle(0))
        
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showMixer" {
            if self.newBlock == nil {
                let popup = PopupDialog(title: "Sorry", message: "Compose Something First...")
                let ok = DefaultButton(title: "OK", action: nil)
                popup.addButton(ok)
                self.present(popup, animated: true, completion: nil)
                return false
            } else {
                return true
            }
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTracks" {
            let vc = segue.destination as! TrackSelectorViewController
            vc.block = sender as! MusicBlock
        } else if segue.identifier == "showMixer" {
            let vc = segue.destination as! BlockInfoEditViewController
            vc.piece = self.piece
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "pieceEditorCell", for: indexPath) as! BillboardCellView
        switch indexPath.row {
        case 0:
            cell.playStopBtn.isHidden = false
            if let block = self.mainBlockSerializer {
                
                cell.isHidden = false
                cell.title.text = "Main Block"
                cell.artist.text = block.title
//                print(block.composedBy?.avatar)
                cell.avatarData = block.composedBy?.avatar as Data?
            } else {
                cell.isHidden = true
            }
            
        case 1:
            cell.playStopBtn.isHidden = false
            if let block = self.secondBlockSerializer {
                cell.isHidden = false
                cell.title.text = "Second Block"
                cell.artist.text = block.title
                cell.avatarData = block.composedBy?.avatar as Data?
            } else {
                cell.isHidden = true
            }
        default:
            guard mainBlock != nil && secondBlock != nil else {
                cell.isHidden = true
                return cell
            }
            cell.isHidden = false
            cell.title.text = "New Block"
            if let data = currentUser?.avatar{
                cell.avatarData = data
            }
            cell.artist.text = piece.title
            if self.newBlock == nil {
                cell.playStopBtn.isHidden = true
            } 
            
        }
        cell.date.isHidden = true
        cell.delegate = self
        cell.likeBtn.isHidden = true
        cell.shareBtnIcon = Icon.menu
        cell.indexPath = indexPath
        return cell
    }
    
    func done() {
        if chossingMainBlock {
            guard self.mainBlock != nil else {
                return
            }
        } else {
            guard self.secondBlock != nil else {
                return
            }
        }
        appDelegate.saveContext()
        PlaybackEngine.shared.addMusicBlock(musicBlock: self.mainBlock)
        fetch()
        popVC.dropDown()
        self.fabMenu.isHidden = false
    }
    
    func blockSelected(sender: PopViewCollectionCell, block: MusicBlock) {
        //
        if self.chossingMainBlock {
            self.mainBlock = block
            piece.mainBlock = block.url
        } else {
            self.secondBlock = block
            piece.secondBlock = block.url
        }
    }
    
    func blockDeselected(sender: PopViewCollectionCell) {
        //
    }
}


class Scene: SKScene {
    
    var timer = 0
    
    let backgroundNode = BackgroundNode()
    let notedropTexture = SKTexture(image: #imageLiteral(resourceName: "Notes"))
    override func sceneDidLoad() {
        backgroundNode.setup(size: size)
        addChild(backgroundNode)
    }
    
    func spawnNotedrop(position: CGPoint) {
        let size = CGSize(width: 30, height: 30)
        let notedrop = SKSpriteNode(texture: notedropTexture)
        notedrop.size = size
        notedrop.color = UIColor.randomColor()
        notedrop.colorBlendFactor = 1
        notedrop.physicsBody = SKPhysicsBody(texture: notedropTexture, size: notedrop.size)
        notedrop.position = position
        addChild(notedrop)
    }
    
//    override func update(_ currentTime: TimeInterval) {
//        timer += 1
//        if timer > 20 {
//            timer = 0
//            spawnNotedrop(position: CGPoint(x: size.width / 2.0, y: size.height))
//        }
//    }
    
}

class BackgroundNode : SKNode {
    
    func setup(size : CGSize) {
        let yPos : CGFloat = size.height * 0.2
        let startPoint = CGPoint(x: 0, y: yPos)
        let endPoint = CGPoint(x: size.width, y: yPos)
        physicsBody = SKPhysicsBody(edgeFrom: startPoint, to: endPoint)
        physicsBody?.restitution = 0.3
    }
}



