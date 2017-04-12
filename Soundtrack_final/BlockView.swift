//
//  BlockView.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/10/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Material

@IBDesignable class BlockView: UIView, UIToolbarDelegate {
    var view: UIView!
    
    @IBOutlet weak var blockCategoryLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var changeBtn: UIButton!
    
    var delegate: BlockViewDelegate?
    
    var musicBlockSerializer: MusicBlockSerializer! {
        didSet {
            DispatchQueue.main.async {
                self.titleLabel.text = self.musicBlockSerializer.title
                self.artistLabel.text = self.musicBlockSerializer.composedBy?.name
                
                self.titleLabel.isHidden = false
                self.artistLabel.isHidden = false
            }
            
        }
    }
    
    var blockCategory: String! {
        didSet {
            DispatchQueue.main.async {
                self.blockCategoryLabel.isHidden = false
                self.blockCategoryLabel.text = self.blockCategory
            }
        }
    }
    
    var musicBlock: MusicBlock? {
        didSet {
            self.playBtn.isEnabled = true
        }
    }
    
    func xibSetup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
    }
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "BlockView", bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first as! UIView
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        xibSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        xibSetup()
    }
    
    override func layoutSubviews() {
        playBtn.setImage(Icon.cm.play, for: .normal)
        playBtn.setTitle("Play", for: .normal)
        playBtn.setImage(Icon.cm.pause, for: .selected)
        playBtn.setTitle("Stop", for: .selected)
        changeBtn.setImage(Icon.cm.audioLibrary, for: .normal)
        blockCategoryLabel.isHidden = true
        titleLabel.isHidden = true
        artistLabel.isHidden = true
        if self.musicBlock == nil {
            self.playBtn.isEnabled = false
        }
    }
    @IBAction func playBtnTapped(_ sender: UIButton) {
        if !playBtn.isSelected {
            if self.musicBlock != nil {
                PlaybackEngine.shared.addMusicBlock(musicBlock: musicBlock!)
                PlaybackEngine.shared.playSequence()
                delegate?.playBtnTapped()
                playBtn.isSelected = true
            }
        } else {
            PlaybackEngine.shared.stopSequence()
            playBtn.isSelected = false
        }
    }
    
    @IBAction func changeBtnTapped(_ sender: UIButton) {
        delegate?.changeBtnTapped(from: self.blockCategory)
    }
}

protocol BlockViewDelegate {
    func changeBtnTapped(from: String)
    func playBtnTapped()
}
