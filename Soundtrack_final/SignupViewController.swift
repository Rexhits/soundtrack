//
//  SignupViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import AFNetworking
import Lockbox
import SwiftyJSON

class SignupViewController: UIViewController {
    
    @IBOutlet var statusLabel: UILabel!
    
    @IBOutlet var emailField: UITextField!
    
    @IBOutlet var usernameFiled: UITextField!
    
    @IBOutlet var passwordField: UITextField!
    
    let manager = AFHTTPSessionManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func signup(_ sender: UIButton) {
        let package = ["email": self.emailField.text!, "password": self.passwordField.text!, "username": usernameFiled.text!]
        self.manager.responseSerializer = AFJSONResponseSerializer()
        self.manager.post("http://127.0.0.1:8000/users/register", parameters: package, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            self.statusLabel.isHidden = true
            let json = response as! Dictionary<String, AnyObject>
            if let t = json["token"]{
                print("Token saved! \(Lockbox.archiveObject(t as! NSString, forKey: "Token"))")
            }
            self.performSegue(withIdentifier: "gotoIndexFromSignup", sender: self)
        }) { (task: URLSessionDataTask?, err: Error) in
            if task?.response != nil {
                let response = task!.response as! HTTPURLResponse
                print("NO! \(err)")
                switch response.statusCode {
                case 400:
                    self.statusLabel.text = "Invalid Email or Password, Please try again"
                    self.statusLabel.isHidden = false
                default:
                    self.statusLabel.text = "Unable to reach server now... Please try again later"
                    self.statusLabel.isHidden = false
                }
                
            }
        }
        
    }
    
}
