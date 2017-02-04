//
//  TemplateSelViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/18/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit

class TemplateSelViewController: UIViewController, PopViewDelegate {
    
    
    @IBOutlet weak var selectedCellTitle: UILabel!
    
    var piece: Piece!
    
    override func viewDidLoad() {
        if let childVC = self.childViewControllers.first {
            if let popVC = childVC as? PopViewController {
                popVC.delegate = self
            }
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        if let childVC = self.childViewControllers.first {
            if let popVC = childVC as? PopViewController {
                popVC.pullUp()
            }
        }
    }
    
    func blockSelected(sender: PopViewCollectionCell, block: MusicBlock) {
        self.selectedCellTitle.text = sender.title.text
        Evolution.shared.mainBlock = block
    }
    
    func blockDeselected(sender: PopViewCollectionCell) {
        Evolution.shared.mainBlock = nil
    }
    func done() {
        self.performSegue(withIdentifier: "gotoPieceEditor", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoPieceEditor" {
            let target = segue.destination as! PieceEditorViewController
            target.piece = self.piece
        }
    }
}
