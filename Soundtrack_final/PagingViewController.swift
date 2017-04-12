//
//  PagingViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/9/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import PageMenu
import SwiftyJSON

class PagingViewController: UIViewController {
    var pageMenu: CAPSPageMenu?
    
    var piece: Piece!
    var mainBlock: MusicBlock!
    var secondBlock: MusicBlock!
    var mainBlockSerializer: MusicBlockSerializer!
    var secondBlockSerializer: MusicBlockSerializer!
    
    var newBlock: MusicBlock?
    
    var blockSelectionVC: BlockSelectionViewController!
    var clipsManagementVC: ClipsManagementViewController!
    var composeVC: ComposeViewController!
    
    override func viewDidLoad() {
        
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        if blockSelectionVC == nil {
            blockSelectionVC = storyBoard.instantiateViewController(withIdentifier: "blockSelectionVC") as! BlockSelectionViewController
            blockSelectionVC.title = "Blocks"
            blockSelectionVC.rootVC = self
        }
        if clipsManagementVC == nil {
            clipsManagementVC = storyBoard.instantiateViewController(withIdentifier: "clipsManagementVC") as! ClipsManagementViewController
            clipsManagementVC.title = "Clips"
            clipsManagementVC.rootVC = self
        }
        if composeVC == nil {
            composeVC = storyBoard.instantiateViewController(withIdentifier: "composeVC") as! ComposeViewController
            composeVC.title = "Composition"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetch()
        setupPageVC()
    }
    
//    override func viewDidLayoutSubviews() {
//        
//    }
    
    func setupPageVC() {
        let controllerArray: [UIViewController] = [blockSelectionVC, clipsManagementVC, composeVC]
        let parameters: [CAPSPageMenuOption] = [.menuItemSeparatorWidth(4.3),.useMenuLikeSegmentedControl(true),.menuItemSeparatorPercentageHeight(0.1)]
        
        pageMenu = CAPSPageMenu(viewControllers: controllerArray, frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height) , pageMenuOptions: parameters)
        addChildViewController(pageMenu!)
        self.view.addSubview(pageMenu!.view)
        pageMenu!.didMove(toParentViewController: self)
        pageMenu?.delegate = self
    }
}

extension PagingViewController {
    func fetch() {
        if let url = piece.mainBlock {
            ServerCommunicator.shared.get(url: url, body: nil, completion: { (response, err, errCode) in
                guard response != nil else {return}
                let json = JSON(response!)
                self.mainBlockSerializer = MusicBlockSerializer(json: json)
                self.mainBlock = self.mainBlockSerializer.getMusicBlock(json: json)
                self.blockSelectionVC.getBlocks()
            })
        }
        if let url = piece.secondBlock {
            ServerCommunicator.shared.get(url: url, body: nil, completion: { (response, err, errCode) in
                guard response != nil else {return}
                let json = JSON(response!)
                self.secondBlockSerializer = MusicBlockSerializer(json: json)
                self.secondBlock = self.secondBlockSerializer.getMusicBlock(json: json)
                self.blockSelectionVC.getBlocks()
            })
        }
        
    }

}

extension PagingViewController: CAPSPageMenuDelegate {
    func willMoveToPage(_ controller: UIViewController, index: Int) {
        //
    }
    func didMoveToPage(_ controller: UIViewController, index: Int) {
        pageMenu?.moveToPage(index)
    }
    
}

