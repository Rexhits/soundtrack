//
//  Segues.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/12/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit

class ZoomOut: UIStoryboardSegue {
    override func perform() {
        let firstVC = self.source as! MixerViewController
        let secondVC = self.destination as! MixerPopoverViewController
        let window = UIApplication.shared.keyWindow
        window?.insertSubview(secondVC.view, aboveSubview: firstVC.view)
        let zoomOut = CGAffineTransform(scaleX: 5, y: 5)
        let restore = CGAffineTransform(scaleX: 0, y: 0)
        secondVC.view.backgroundColor = secondVC.view.backgroundColor?.withAlphaComponent(0)
        UIView.animate(withDuration: 0.8, animations: {
            firstVC.mixerTable.transform = zoomOut
            firstVC.view.backgroundColor = secondVC.view.backgroundColor
            secondVC.view.backgroundColor = secondVC.view.backgroundColor?.withAlphaComponent(1)
        }, completion: {finished in
            firstVC.view.transform = restore
            firstVC.navigationController?.isNavigationBarHidden = true
            firstVC.navigationController?.pushViewController(secondVC, animated: false)
            self.source.dismiss(animated: false, completion: nil)
        })
        

    }
}

class ZoomIn: UIStoryboardSegue {
    override func perform() {
        let firstVC = self.source as! MixerPopoverViewController
        let firstVCView = firstVC.view
        let secondVC = self.destination as! MixerViewController
        let secondVCView = secondVC.view
        secondVCView?.backgroundColor = secondVCView?.backgroundColor?.withAlphaComponent(0)
        let window = UIApplication.shared.keyWindow
        window?.insertSubview(secondVCView!, aboveSubview: firstVCView!)
        UIView.animate(withDuration: 0.4, animations: {
            secondVCView?.transform = CGAffineTransform(scaleX: -5, y: -5)
            firstVCView?.backgroundColor = firstVCView?.backgroundColor?.withAlphaComponent(1)
        }, completion: {completion in
            
            self.source.dismiss(animated: false, completion: nil)
        })
    }
}
