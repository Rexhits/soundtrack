//
//  BillboardExtention.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/12/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import Foundation
import UIKit
import CoreData

let appDelegate = UIApplication.shared.delegate as! AppDelegate


struct UserInfo {
    var id: Int?
    var username: String?
    var avatar: Data?
    var email: URL?
    var selfIntro: String?
    var country: String?
    var city: String?
    let keys = ["Username", "Email", "Self Intro", "Country", "City", "Genres"]
    let searchKeys = ["displayName", "email", "selfIntro", "country", "city", "favoriteGenres"]
    var values = [String]()
    init() {
        
    }
    init(json: [String: AnyObject]) {
        id = json["id"] as? Int
        username = json["displayName"] as? String
        switch json["avatar"] {
        case let img as String:
            do {
                avatar = try Data(contentsOf: URL(string: img)!)
            } catch {
                print(error)
            }
            
        default:
            break
        }
        email = json["email"] as? URL
        selfIntro = json["selfIntro"] as? String
        country = json["country"] as? String
        city = json["city"] as? String
        for i in searchKeys {
            let value = json[i]
            switch value {
            case let value as String:
                values.append(value)
            case is NSNull:
                values.append("Unknown")
            default:
                break
            }
        }
    }
}

extension Billboard {
    convenience init(json: JSONPackage) {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
        name = json["name"] as? String
        info = json["info"] as? String
        address1 = json["address1"] as? String
        address2 = json["address2"] as? String
        latitude = json["latitude"] as! Double
        longitude = json["longitude"] as! Double
    }
}

extension Piece {
    convenience init(title: String) {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
        self.title = title
        Server.get(api: "users/current", body: nil) { (response, err, errCode) in
            guard err == nil, errCode == nil else {
                switch errCode! {
                case 403:
                    print("Need re-login")
                default:
                    break
                }
                return
            }
            guard response != nil else {return}
            let res = response! as! JSONPackage
            self.composedBy = res["displayName"] as? String
        }

    }
}
