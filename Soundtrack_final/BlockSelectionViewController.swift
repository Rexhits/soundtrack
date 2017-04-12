//
//  WorkflowViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/9/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Material

class BlockSelectionViewController: UITableViewController {
    
    var piece: Piece!
    

    var rootVC: PagingViewController!
    
    var changeBlockTarget: String!
    
    var mainBlockView: BlockView!
    
    var secondBlockView: BlockView!
    
    var newBlockView: BlockView!
    
    var popVC: PopViewController!
    
    override func viewDidLoad() {
        mainBlockView = BlockView()
        secondBlockView = BlockView()
        newBlockView = BlockView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        configureBlocks()
        getBlocks()
        self.piece = rootVC.piece
//        stackView.layoutIfNeeded()
//        stackView.layoutSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        mainBlockView.view.backgroundColor = UIColor.hexStringToUIColor(hex: "#b348ff")
        secondBlockView.view.backgroundColor = UIColor.hexStringToUIColor(hex: "#916ff2")
        newBlockView.view.backgroundColor = UIColor.hexStringToUIColor(hex: "#6f97e5")
        newBlockView.changeBtn.isHidden = true
    }
    
    func configureBlocks() {
        mainBlockView.blockCategory = "Main Block"
        secondBlockView.blockCategory = "Aux Block"
        newBlockView.blockCategory = "Block You Composed"
        
        mainBlockView.delegate = self
        secondBlockView.delegate = self
        newBlockView.delegate = self
    }
    
    func getBlocks() {
        if let mainBlock = rootVC.mainBlock {
            mainBlockView.musicBlock = mainBlock
        }
        
        if let mainBlockSerializer = rootVC.mainBlockSerializer {
            mainBlockView.musicBlockSerializer = mainBlockSerializer
        }

        if let secondBlock = rootVC.secondBlock {
            secondBlockView.musicBlock = secondBlock
        }

        if let secondBlockSerializer = rootVC.secondBlockSerializer {
            secondBlockView.musicBlockSerializer = secondBlockSerializer
        }
        
        if let newBlock = rootVC.newBlock {
            newBlockView.musicBlock = newBlock
            newBlock.composedBy = currentUser!.username!
        }
        
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            mainBlockView.frame = cell.contentView.bounds
            cell.contentView.addSubview(mainBlockView)
        } else if indexPath.row == 1 {
            secondBlockView.frame = cell.contentView.bounds
            cell.contentView.addSubview(secondBlockView)
        } else {
            newBlockView.frame = cell.contentView.bounds
            cell.addSubview(newBlockView)
        }
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.view.frame.height / 3
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.popVC != nil {
            self.popVC.dropDown()
            popVC.delegate = nil
            popVC.view.removeFromSuperview()
            popVC.removeFromParentViewController()
            self.popVC = nil
        }
    }
}

extension BlockSelectionViewController: PopViewDelegate {
    func done() {
        //
        appDelegate.saveContext()
    }
    func blockDeselected(sender: PopViewCollectionCell) {
        //
    }
    func blockSelected(sender: PopViewCollectionCell, block: MusicBlock) {
        //
        switch changeBlockTarget {
        case "Main Block":
            rootVC.mainBlock = block
            rootVC.mainBlockSerializer.title = block.name
            rootVC.mainBlockSerializer.composedBy?.name = block.composedBy
            piece.mainBlock = block.url
            
        case "Aux Block":
            rootVC.secondBlock = block
            rootVC.secondBlockSerializer!.title = block.name
            rootVC.secondBlockSerializer!.composedBy?.name = block.composedBy
            piece.secondBlock = block.url
        default:
            break
        }
        getBlocks()
    }
}


extension BlockSelectionViewController: BlockViewDelegate {
    func changeBtnTapped(from: String) {
        changeBlockTarget = from
        if self.popVC == nil {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            popVC = storyBoard.instantiateViewController(withIdentifier: "popVC") as! PopViewController
            popVC.view.frame = self.tableView.bounds
            popVC.delegate = self
            addChildViewController(popVC)
            self.view.addSubview(popVC.view)
            popVC.didMove(toParentViewController: self)
        }
        popVC.pullUp()
    }
    func playBtnTapped() {
        mainBlockView.playBtn.isSelected = false
        secondBlockView.playBtn.isSelected = false
        newBlockView.playBtn.isSelected = false
    }
}
