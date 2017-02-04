//
//  PieceEditorViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/12/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit

class PieceEditorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, PopViewDelegate {
    
    var piece: Piece!
    
    var popView: PopViewController!
    
    
    @IBOutlet weak var partsCollection: UICollectionView!
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.gray
        if let childVC = self.childViewControllers.first {
            if let popView = childVC as? PopViewController {
                self.popView = popView
            }
        }
        popView.delegate = self
        self.partsCollection.delegate = self
        self.partsCollection.dataSource = self
    }
    
    
    
    var blocks = [MusicBlock]()
    var selectedRow = Int()
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return blocks.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let pieceCell = partsCollection.dequeueReusableCell(withReuseIdentifier: "pieceEditorCell", for: indexPath) as! PieceEditorCell
        let addCell = partsCollection.dequeueReusableCell(withReuseIdentifier: "addCell", for: indexPath) as! AddCell
        guard indexPath.row != partsCollection.numberOfItems(inSection: indexPath.section) - 1 else {
            addCell.title.text = "+"
            return addCell
        }
        pieceCell.title.text = blocks[indexPath.row].name
        return pieceCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row != partsCollection.numberOfItems(inSection: indexPath.section) - 1 else {
            let newBlock = MusicBlock(name: String(indexPath.row + 1), composedBy: "user")
            newBlock.tempo = Evolution.shared.mainBlock.tempo
            self.blocks.append(newBlock)
            self.partsCollection.reloadData()
            return
        }
        PlaybackEngine.shared.addMusicBlock(musicBlock: blocks[indexPath.row])
        PlaybackEngine.shared.playSequence()
        selectedRow = indexPath.row
        popView.pullUp()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        PlaybackEngine.shared.stopSequence()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = piece.title
        let bgView = UIControl(frame: self.partsCollection.frame)
        bgView.addTarget(self, action: #selector(touchedScreen(_:)), for: .touchDown)
        bgView.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        self.partsCollection.backgroundView = bgView
    }
    
    @IBAction func touchedScreen(_ sender: UIControl) {
        popView.dropDown()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func blockSelected(sender: PopViewCollectionCell, block: MusicBlock) {
        Evolution.shared.secondBlock = block
    }
    
    func blockDeselected(sender: PopViewCollectionCell) {
        Evolution.shared.secondBlock = nil
    }
    
    func done() {
        self.blocks[selectedRow] = Evolution.shared.generateNewContent()
    }
}
