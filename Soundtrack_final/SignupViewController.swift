//
//  SignupViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import Lockbox

class SignupViewController: UIViewController {
    
    @IBOutlet var statusLabel: UILabel!
    
    @IBOutlet var emailField: UITextField!
    
    @IBOutlet var usernameFiled: UITextField!
    
    @IBOutlet var passwordField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signup(_ sender: UIButton) {
        guard !emailField.text!.isEmpty && !usernameFiled.text!.isEmpty && !passwordField.text!.isEmpty else {
            self.statusLabel.text = "All the fields are required"
            self.statusLabel.isHidden = false
            return
        }
        guard emailField.text!.isValidEmail() else {
            self.statusLabel.text = "Invalid Email, Please try again"
            self.statusLabel.isHidden = false
            return
        }
        guard passwordField.text!.isValidPassword() else {
            self.statusLabel.text = "Password is too weak\nMust be at least 8 characters, contains both letters and digits"
            self.statusLabel.numberOfLines = 3
            self.statusLabel.isHidden = false
            return
        }
        let package = ["email": self.emailField.text!, "password": self.passwordField.text!, "username": usernameFiled.text!]
        Server.post(api: "register", body: package as JSONPackage) { (response, err, errCode) in
            guard err == nil, errCode == nil else {
                switch errCode! {
                case 400, 500:
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
                self.performSegue(withIdentifier: "gotoIndexFromSignup", sender: self)
            }
        }
        
    }
    
}
