//
//  PieceEditorCell.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/18/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit

class PieceEditorCell: UICollectionViewCell {
    
    @IBOutlet weak var title: UILabel!
    
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = (self.isSelected) ? UIColor.orange : UIColor.orange.withAlphaComponent(0.7)
            self.title.textColor = (self.isSelected) ? UIColor.white: UIColor.black
        }
    }
    
    
    override func prepareForReuse() {
        self.isSelected = false
        self.isHighlighted = false
        super.prepareForReuse()
    }
    
    override func layoutSubviews() {
        self.backgroundColor = UIColor.orange.withAlphaComponent(0.7)
        self.title.textColor = UIColor.black
    }
}
