//
//  addCell.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/18/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit

class AddCell: UICollectionViewCell {
    
    @IBOutlet weak var title: UILabel!
    
    override var isSelected: Bool {
        didSet {
            self.backgroundColor = (self.isSelected) ? UIColor.orange : UIColor.blue.withAlphaComponent(0.4)
            self.title.textColor = (self.isSelected) ? UIColor.black : UIColor.white
        }
    }
    
    override func prepareForReuse() {
        self.isSelected = false
        self.isHighlighted = false
        super.prepareForReuse()
    }

    override func layoutSubviews() {
        self.backgroundColor = UIColor.blue.withAlphaComponent(0.4)
        self.title.textColor = UIColor.white
        self.frame = CGRect(origin: self.frame.origin, size: CGSize(width: self.bounds.height, height: self.bounds.height))
        self.layer.cornerRadius = self.layer.bounds.height / 2
    }
}
