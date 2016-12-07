//
//  ViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/5/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import AFNetworking
import SwiftyJSON
import Lockbox

class LoginViewController: UIViewController {
    
    @IBOutlet var statusLabel: UILabel!

    @IBOutlet var emailField: UITextField!
    
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

    @IBAction func login(_ sender: UIButton) {
        let package = ["username": self.emailField.text!, "password": self.passwordField.text!]
//        self.manager.responseSerializer = AFHTTPResponseSerializer()
        self.manager.post("http://localhost:8000/api-token-auth/", parameters: package, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            self.statusLabel.isHidden = true
            
//            let token = NSString(data: response! as! Data, encoding: String.Encoding.utf8.rawValue)
            let response = JSON(response!)
            let token = "token: \(response["token"].description)" as NSString
            print("Token saved! \(Lockbox.archiveObject(token, forKey: "Token"))")
            self.performSegue(withIdentifier: "gotoIndex", sender: self)
            
        }) { (task: URLSessionDataTask?, err: Error) in
            if task?.response != nil {
                let response = task!.response as! HTTPURLResponse
                print("NO! \(response.statusCode)")
                switch response.statusCode {
                case 401, 400, 403:
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

