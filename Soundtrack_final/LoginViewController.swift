//
//  ViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/5/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import Lockbox

class LoginViewController: UIViewController {
    
    @IBOutlet var statusLabel: UILabel!

    @IBOutlet var emailField: UITextField!
    
    @IBOutlet var passwordField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func login(_ sender: UIButton) {
        let package = ["username": self.emailField.text!, "password": self.passwordField.text!]
        Server.post(api: "api-token-auth", body: package as JSONPackage) { (response, err, errCode) in
            guard err == nil, errCode == nil else {
                switch errCode! {
                case 401, 400, 403:
                    self.statusLabel.text = "Invalid Email or Password, Please try again"
                    self.statusLabel.isHidden = false
                default:
                    self.statusLabel.text = "Unable to reach server now... Please try again later"
                    self.statusLabel.isHidden = false
                }
                return
            }
            self.statusLabel.isHidden = true
            guard response != nil else {return}
            let res = response! as! JSONPackage
            if let t = res["token"]{
                let token = "Token \(t as! String)" as NSString
                print("Token saved! \(Lockbox.archiveObject(token, forKey: "Token"))")
                self.performSegue(withIdentifier: "gotoIndex", sender: self)
            }
        }
        
    }

}

