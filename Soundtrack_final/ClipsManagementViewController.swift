//
//  ClipsManagementViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/9/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Material

class ClipsManagementViewController: UIViewController {
    
    var piece: Piece!
    
    var rootVC: PagingViewController!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var fromMainBtn: RaisedButton!
    
    @IBOutlet weak var fromSecondBtn: RaisedButton!
    
    override func viewWillAppear(_ animated: Bool) {
        setupButtons()
        self.piece = rootVC.piece
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoMainBlock" {
            let vc = segue.destination as! TrackSelectorViewController
            vc.block = rootVC.mainBlock
        } else if segue.identifier == "gotoSecondBlock" {
            let vc = segue.destination as! TrackSelectorViewController
            vc.block = rootVC.secondBlock
        }
    }
}

extension ClipsManagementViewController {
    func setupButtons() {
        fromMainBtn.titleColor = UIColor.white
        fromMainBtn.pulseColor = .white
        fromMainBtn.backgroundColor = Color.blue.base
        fromMainBtn.setImage(Icon.add, for: .normal)
        fromSecondBtn.titleColor = UIColor.white
        fromSecondBtn.pulseColor = .white
        fromSecondBtn.backgroundColor = Color.purple.base
        fromSecondBtn.setImage(Icon.add, for: .normal)
    }
}
