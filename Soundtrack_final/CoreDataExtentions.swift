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
import SwiftyJSON

let appDelegate = UIApplication.shared.delegate as! AppDelegate

class MusicBlockSerializer {
    var title: String?
    var url: String?
    var audioUrl: String?
    var composedBy: ComposerSerializer?
    var date: String?
    var id: Int?
    var saved: Bool?
    var collected: Bool?
    var composed: Bool?
    var delegate: MusicBlockSerializerDelegate?
    static let shared = MusicBlockSerializer()
    
    init() {
        
    }
    
    init (json: JSON) {
        fromJSON(json: json)
    }
    
    func fromJSON(json:JSON) {
        title = json["title"].stringValue
        url = json["url"].stringValue
        audioUrl = json["audioFile"].stringValue
        composedBy = ComposerSerializer(json: json["composedBy"])
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let _date = dateFormatter.date(from: json["createdAt"].stringValue)
        if let d = _date {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            date = dateFormatter.string(from: d)
        }
        if url != nil {
            id = url!.getIDFromURL()!
        }
        
        if let user = currentUser {
            if composedBy?.id == user.id {
                self.composed = true
            }
            for i in json["savedBy"] {
                let id = i.1.stringValue.getIDFromURL()
                if id == user.id {
                    self.saved = true
                }
            }
        }
    }
    
    func getMusicBlock(json: JSON) -> MusicBlock {
        fromJSON(json: json)
        STFileManager.shared.emptyTempFoler()
        let midifileURL = URL(string: json["midiFile"].stringValue)
        let jsonfileURL = URL(string: json["jsonFile"].stringValue)
        let midiData = try! Data.init(contentsOf: midifileURL!)
        let jsonData = try! Data.init(contentsOf: jsonfileURL!)
        let musicblock = MusicBlock(jsonFile: jsonData, midiFile: midiData)
        musicblock.url = self.url
        musicblock.composedBy = self.composedBy!.name!
        self.delegate?.blockConfigured(block: musicblock)
        return musicblock
    }
    
    
    
    func downloader(urls: [URL], completion: @escaping ([URL])->Void) {
        var outputUrls = [URL]()
        for i in urls {
            let instPreset = STFileManager.shared.getTempDir().appendingPathComponent("\(i.fileName()).aupreset")
            let session = URLSession(configuration: .default)
            let task = session.downloadTask(with: i, completionHandler: { (tempLocalUrl, response, error) in
                if let tempLocalUrl = tempLocalUrl, error == nil {
                    // Success
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        print("Successfully downloaded. Status code: \(statusCode)")
                    }
                    
                    do {
                        try FileManager.default.copyItem(at: tempLocalUrl, to: instPreset)
                        outputUrls.append(instPreset)
                        if outputUrls.count == urls.count {
                            completion(outputUrls)
                        }
                    } catch (let writeError) {
                        print("Error creating a file \(i) : \(writeError)")
                    }
                    
                } else {
                    print("Error took place while downloading a file.\(error!.localizedDescription)")
                }
            })
            task.resume()
        }
    }
    
}

extension MusicBlockSerializer: Hashable {
    var hashValue: Int {
        guard self.id != nil else {
            return -1
        }
        return id!
    }
    static func == (lhs: MusicBlockSerializer, rhs: MusicBlockSerializer) -> Bool {
        let equal = lhs.id == rhs.id
        return equal
    }
}

protocol MusicBlockSerializerDelegate {
    func blockConfigured(block: MusicBlock)
}



class ComposerSerializer: Hashable {
    var name: String?
    var avatar: NSData?
    var id: Int?
    init(json: JSON) {
        name = json["displayName"].stringValue
        id = json["id"].intValue
        let urlString = json["avatar"].stringValue
        let url = URL(string: urlString)
        if let url = url {
            do {
                avatar = try Data(contentsOf: url) as NSData
            } catch {
                print("unable to get avatar")
            }
        }
    }
    
    var hashValue: Int {
        guard id != nil else {
            return -1
        }
        return id!
    }
    
    static func == (lhs: ComposerSerializer, rhs: ComposerSerializer) -> Bool {
        let equal = lhs.id == rhs.id
        return equal
    }
}

class PieceSerializer: Hashable {
    var url: String?
    var title: String?
    var audioUrl: String?
    var id: Int?
    var composedBy: ComposerSerializer?
    var collectedBy: UserInfo?
    var onboard: BillboardSerializer?
    var date: String?
    var saved = false
    var composed = false
    init(json: JSON) {
        title = json["title"].stringValue
        url = json["url"].stringValue
        self.id = url?.getIDFromURL()
        audioUrl = json["audioFile"].stringValue
        composedBy = ComposerSerializer(json: json["composedBy"])
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let _date = dateFormatter.date(from: json["createdAt"].stringValue)
        if let d = _date {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            date = dateFormatter.string(from: d)
        }
        if let user = currentUser {
            if composedBy?.id == user.id {
                self.composed = true
            }
            for i in json["collectedBy"] {
                let id = i.1.stringValue.getIDFromURL()
                if id == user.id {
                    self.saved = true
                }
            }
        }
    }
    var hashValue: Int {
        guard id != nil else {
            return -1
        }
        return id!
    }
    
    static func == (lhs: PieceSerializer, rhs: PieceSerializer) -> Bool {
        let equal = lhs.id == rhs.id
        return equal
    }
}

struct UserInfo {
    var id: Int?
    var username: String?
    var avatar: Data?
    var email: URL?
    var selfIntro: String?
    var country: String?
    var city: String?
    var collectedBlocks: [MusicBlockSerializer]?
    var composedBlocks: [MusicBlockSerializer]?
    var collectedPieces: [PieceSerializer]?
    var composedPieces: [PieceSerializer]?
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
        if let composed = json["composedBlocks"] {
            let composed_json = JSON(composed)
            composedBlocks = composed_json.map{MusicBlockSerializer.init(json: $0.1)}
        }
        if let collected = json["savedBlocks"] {
            let collected_json = JSON(collected)
            collectedBlocks = collected_json.map{MusicBlockSerializer.init(json: $0.1)}
        }
        
        if let composed_P = json["composedMusic"] {
            let composed_json = JSON(composed_P)
            composedPieces = composed_json.map{PieceSerializer.init(json: $0.1)}
        }
        
        if let collected_P = json["collectedMusic"] {
            let collected_json = JSON(collected_P)
            collectedPieces = collected_json.map{PieceSerializer.init(json: $0.1)}
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
        url = json["url"] as? String
    }
}

extension Clip {
    convenience init(length: Double, data: NSData, fromMainBlock: Bool?) {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
        if let fromMain = fromMainBlock {
            self.fromMainBlock = fromMain
        }
        self.length = length
        self.midiData = data
    }
    convenience init() {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
    }
}

extension TrackData {
    convenience init(volume: Double, pan: Double) {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
        self.pan = Float(pan)
        self.volume = Float(volume)
    }
}

extension Composer {
    convenience init(json: JSON) {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
        name = json["displayName"].stringValue
        let urlString = json["avatar"].stringValue
        let url = URL(string: urlString)
        if let url = url {
            do {
                avatar = try Data(contentsOf: url) as NSData
            } catch {
                print("unable to get avatar")
            }
            
        }
    }
    convenience init(serializer: ComposerSerializer) {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
        name = serializer.name
        avatar = serializer.avatar
    }
}

extension MusicBlockData {
    convenience init(json: JSON) {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
        title = json["title"].stringValue
        url = json["url"].stringValue
        audioUrl = json["audioFile"].stringValue
        composedBy = Composer(json: json["composedBy"])
        if url != nil {
            id = Int32(url!.getIDFromURL()!)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let _date = dateFormatter.date(from: json["createdAt"].stringValue)
        if let d = _date {
            dateFormatter.dateFormat = "yyyy-MM-dd"
            date = dateFormatter.string(from: d)
        }
    }
    convenience init(serializer: MusicBlockSerializer) {
        let context = appDelegate.persistentContainer.viewContext
        self.init(context: context)
        title = serializer.title
        url = serializer.url
        audioUrl = serializer.url
        composedBy = Composer(serializer: serializer.composedBy!)
        date = serializer.date
        if let id = serializer.id {
            self.id = Int32(id)
        }
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


