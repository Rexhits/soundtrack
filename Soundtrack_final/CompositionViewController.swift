//
//  CompositionViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/9/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation
import RQShineLabel
import PopupDialog

class CompositionViewController: UIViewController {
    
    @IBOutlet weak var skView: SKView!
    
    var scene: SKScene!
    
    var piece: Piece!
    
    
    var shineLabel: ShineLabel!
    
    
    override func viewWillAppear(_ animated: Bool) {
        PlaybackEngine.shared.delegate = self
        setupScene()
        updateLabel(text: "Welcome to the Lab! You can combine two pieces together here")
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        PlaybackEngine.shared.delegate = nil
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "emdedVCs" {
            if let vc = segue.destination as? PagingViewController {
                vc.piece = self.piece
            }
        }
        else if segue.identifier == "showMixer" {
            if let vc = segue.destination as? BlockInfoEditViewController {
                vc.piece = self.piece
                if let finishedClip = self.piece.finishedClip {
                    let block = MusicBlock(clip: finishedClip)
                    PlaybackEngine.shared.updateBlock(newBlock: block)
                }
            }
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "showMixer" {
            if piece.finishedClip == nil {
                let popup = PopupDialog(title: "Sorry", message: "Compose Something First...")
                let ok = DefaultButton(title: "OK", action: nil)
                popup.addButton(ok)
                self.present(popup, animated: true, completion: nil)
                return false
            } else {
                return true
            }
        }
        return true
    }
    
}

extension CompositionViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension CompositionViewController: PlaybackEngineDelegate {
    
    func didStartLoop() {
        //
    }
    func didFinishLoop() {
        //
    }
    func didStartPlaying() {
        //
    }
    func didFinishPlaying() {
        //
    }
    func didLoadBlock(block: MusicBlock) {
        //
    }
    func updateTime(currentTime: AVMusicTimeStamp) {
        //
    }
    
    
}



extension CompositionViewController {
    func addShineLabel() {
        shineLabel = ShineLabel(frame: skView.bounds)
        shineLabel.backgroundColor = UIColor.clear
        shineLabel.numberOfLines = 5
        shineLabel.font = shineLabel.font.withSize(18)
        shineLabel.lineBreakMode = .byWordWrapping
        shineLabel.adjustsFontSizeToFitWidth = true
        shineLabel.isAutoStart = true
        shineLabel.leftInset = 20
        shineLabel.rightInset = 20
        skView.addSubview(shineLabel)
//        skView.layout(shineLabel).center()
    }
    
    func updateLabel(text: String) {
        shineLabel.text = text
    }
    
    func updateLabelWithFadeOut(text: String) {
        shineLabel.text = text
        shineLabel.shine { 
            self.shineLabel.fadeOut()
        }
    }
    
    
    
    func setupScene() {
        scene = SKScene(size: skView.bounds.size)
        skView.presentScene(scene)
        addShineLabel()
    }
    func addSpark(pos: CGPoint, velocity: Int, duration: TimeInterval) {
        let sparkNode = SKEmitterNode(fileNamed: "spark")
        sparkNode?.particlePosition = pos
        sparkNode?.particleBirthRate = 500
        sparkNode?.numParticlesToEmit = Int(500 * duration)
        sparkNode?.particleAlpha = CGFloat(velocity) / 128
        scene.addChild(sparkNode!)
        scene.run(SKAction.wait(forDuration: duration + 1)) {
            sparkNode?.removeFromParent()
        }
    }
    
}

class ShineLabel: RQShineLabel {
    var topInset: CGFloat = 0.0
    var leftInset: CGFloat = 0.0
    var bottomInset: CGFloat = 0.0
    var rightInset: CGFloat = 0.0
    
    var insets: UIEdgeInsets {
        get {
            return UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset)
        }
        set {
            topInset = newValue.top
            leftInset = newValue.left
            bottomInset = newValue.bottom
            rightInset = newValue.right
        }
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var adjSize = super.sizeThatFits(size)
        adjSize.width += leftInset + rightInset
        adjSize.height += topInset + bottomInset
        
        return adjSize
    }
    
    override var intrinsicContentSize: CGSize {
        var contentSize = super.intrinsicContentSize
        contentSize.width += leftInset + rightInset
        contentSize.height += topInset + bottomInset
        
        return contentSize
    }
}


