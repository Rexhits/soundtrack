//
//  MixerCellView.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/12/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import QuartzCore

class MixerCellView: UICollectionViewCell {
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var trackIndexLabel: UILabel!
    var subVC: MixerSubviewController?
    var delegate: MixerCellDelegate?
    var indexPath: IndexPath?
    var swipeLeft: UISwipeGestureRecognizer!
    var swipeRight: UISwipeGestureRecognizer!
    override func awakeFromNib() {
        swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(openSubview))
        swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(closeSubview(sender:animated:)))
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        swipeRight.direction = UISwipeGestureRecognizerDirection.right
        self.addGestureRecognizer(swipeLeft)
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.4
        self.layer.shadowOffset = CGSize(width: 0, height: 10)
        self.layer.shadowRadius = 10.0
        self.clipsToBounds = false
        self.layer.masksToBounds = false
    }
    
    func openSubview() {
        delegate?.openCellSubview(cell: self, indexPath: indexPath!)
        self.removeGestureRecognizer(swipeLeft)
        self.addGestureRecognizer(swipeRight)
    }
    func closeSubview(sender: Any?, animated: Bool) {
        if let _ = sender as? UISwipeGestureRecognizer {
            delegate?.closeCellSubview(cell: self, indexPath: indexPath!, animated: true)
        } else {
            delegate?.closeCellSubview(cell: self, indexPath: indexPath!, animated: false)
        }
        self.removeGestureRecognizer(swipeRight)
        self.addGestureRecognizer(swipeLeft)
    }
}

protocol MixerCellDelegate {
    func openCellSubview(cell: MixerCellView, indexPath: IndexPath)
    func closeCellSubview(cell: MixerCellView, indexPath: IndexPath, animated: Bool)
}
