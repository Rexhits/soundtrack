//
//  PopViewCollectionCell.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/18/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit

class PopViewCollectionCell: UICollectionViewCell {
    @IBOutlet weak var title: UILabel!
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = (self.isSelected) ? UIColor.orange : UIColor.lightGray
        }
    }
    
    override func prepareForReuse() {
        self.isSelected = false
        self.isHighlighted = false
        super.prepareForReuse()
    }
}

