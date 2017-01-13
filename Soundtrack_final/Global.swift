//
//  Global.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox
import AFNetworking
import Lockbox
import SwiftyJSON

typealias JSONPackage = [String:AnyObject]

let serverURL = "http://localhost:8000/"

final class ServerCommunicator: NSObject {
    static let shared = ServerCommunicator()
    let serverURL = "http://localhost:8000/"
    let manager = AFHTTPSessionManager()
    override init() {
        super.init()
        getToken()
    }
    
    func getToken() {
        let token = Lockbox.unarchiveObject(forKey: "Token")
        if token != nil {
            manager.requestSerializer.setValue(token! as? String, forHTTPHeaderField: "Authorization")
        }
    }
    
    func get(api: String, body:JSONPackage?, completion: @escaping (Any?, Error?, Int?)->Void) {
        getToken()
        manager.get("\(serverURL)\(api)/", parameters: nil, progress: nil, success: { (task:URLSessionDataTask, response: Any?) in
            completion(response, nil, nil)
        }) { (task: URLSessionDataTask?, err: Error) in
            let response = task!.response as! HTTPURLResponse
            completion(nil, err, response.statusCode)
        }
    }
    func post(api: String, body:JSONPackage, completion: @escaping (Any?, Error?, Int?)->Void) {
        getToken()
        manager.post("\(serverURL)\(api)/", parameters: body, progress: nil, success: { (task, response) in
            completion(response, nil, nil)
        }) {(task, err) in
            let response = task!.response as! HTTPURLResponse
            completion(nil, err, response.statusCode)
        }
    }
    
    func patch(api: String, body:JSONPackage, completion: @escaping (Any?, Error?, Int?)->Void) {
        getToken()
        manager.patch("\(serverURL)\(api)/", parameters: body, success: { (task:URLSessionDataTask, response: Any?) in
            completion(response, nil, nil)
        }) { (task: URLSessionDataTask?, err: Error) in
            let response = task!.response as! HTTPURLResponse
            completion(nil, err, response.statusCode)
        }
    }
    
    func uploadAvatar(data:Data, filename: String, completion: @escaping (JSONPackage?, Error?, Int?)->Void) {
        getToken()
        manager.post("\(serverURL)users/avatar/", parameters: nil, constructingBodyWith: { (formData: AFMultipartFormData) in
            formData.appendPart(withFileData: data, name: "avatar", fileName: filename, mimeType: "image/jpeg")
        }, progress: nil, success: {(task:URLSessionDataTask, response: Any?) in
            completion(response as? JSONPackage, nil, nil)
        }) { (task: URLSessionDataTask?, err: Error) in
            let response = task!.response as! HTTPURLResponse
            completion(nil, err, response.statusCode)
        }
    }
}

let Server = ServerCommunicator.shared

let n: UInt8 = 0

func iteratorForTuple(tuple: Any) -> AnyIterator<Any> {
    return AnyIterator(Mirror(reflecting: tuple).children.lazy.map { $0.value }.makeIterator())
}

extension String {
    func isValidEmail() -> Bool {
        let regex = try? NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .caseInsensitive)
        return regex?.firstMatch(in: self, options: [], range: NSMakeRange(0, self.characters.count)) != nil
    }
    func isValidPassword() -> Bool {
        let regex = try? NSRegularExpression(pattern: "^(?=.*?[a-zA-Z])(?=.*?[0-9]).{8,}$", options: .caseInsensitive)
        return regex?.firstMatch(in: self, options: [], range: NSMakeRange(0, self.characters.count)) != nil
    }
}

func getURLInDocumentDirectoryWithFilename (filename: String) -> URL {
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentDirectory = path[0] as String
    let fullpath = "\(documentDirectory)/\(filename)"
    return URL(fileURLWithPath: fullpath)
}



enum auType: UInt32 {
    case instrument, effect
    func getType() -> UInt32 {
        switch self {
        case .instrument:
            return kAudioUnitType_MusicDevice
        default:
            return kAudioUnitType_Effect
        }
    }
}

struct Track: MusicalSequence {
    internal var content: BasicMusicalStructure = BasicMusicalStructure()
    var parser: MIDIParser
    init(parser: MIDIParser) {
        self.parser = parser
    }
    
}

struct Measure: MusicalSequence {
    internal var content: BasicMusicalStructure = BasicMusicalStructure()
    
}

struct Articulation: CustomStringConvertible {
    var status: UInt8 = 0
    var timeStamp: MusicTimeStamp = 0
    var controllerNum:Int = 0
    var value:Int = 0
    var description: String {
        return String("Controller: \(controllerNum)\tValue: \(value)")
    }
}



public extension Sequence where Iterator.Element: Hashable {
    var uniqueElements: [Iterator.Element] {
        return Array(
            Set(self)
        )
    }
}
public extension Sequence where Iterator.Element: Equatable {
    var uniqueElements: [Iterator.Element] {
        return self.reduce([]){
            uniqueElements, element in
            
            uniqueElements.contains(element)
                ? uniqueElements
                : uniqueElements + [element]
        }
    }
}



extension AudioComponentDescription: Equatable {
    public static func ==(lhs: AudioComponentDescription, rhs: AudioComponentDescription) -> Bool {
        return lhs.componentType == rhs.componentType && lhs.componentSubType == rhs.componentSubType && lhs.componentFlags == rhs.componentFlags && lhs.componentFlagsMask == rhs.componentFlagsMask
    }
}

extension JSON {
    public var date: Date? {
        get {
            switch self.type {
            case .string:
                return Formatter.jsonDateFormatter.date(from: self.object as! String)
            default:
                return nil
            }
        }
    }
    
    public var dateTime: Date? {
        get {
            switch self.type {
            case .string:
                return Formatter.jsonDateTimeFormatter.date(from: self.object as! String)
            default:
                return nil
            }
        }
    }
}

class Formatter {
    
    private static var internalJsonDateFormatter: DateFormatter?
    private static var internalJsonDateTimeFormatter: DateFormatter?
    
    static var jsonDateFormatter: DateFormatter {
        if (internalJsonDateFormatter == nil) {
            internalJsonDateFormatter = DateFormatter()
            internalJsonDateFormatter!.dateFormat = "yyyy-MM-dd"
        }
        return internalJsonDateFormatter!
    }
    
    static var jsonDateTimeFormatter: DateFormatter {
        if (internalJsonDateTimeFormatter == nil) {
            internalJsonDateTimeFormatter = DateFormatter()
            internalJsonDateTimeFormatter!.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        }
        return internalJsonDateTimeFormatter!
    }
    
    static func toJSON(date: Date) -> String {
        if (internalJsonDateTimeFormatter == nil) {
            internalJsonDateTimeFormatter = DateFormatter()
            internalJsonDateTimeFormatter!.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
        }
        return internalJsonDateTimeFormatter!.string(from: date)
    }
}

extension Double {
    func milesToMeters() -> Double {
        return self * 1609.344
    }
}

extension UIImage {
    func colorized(color : UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0);
        let context = UIGraphicsGetCurrentContext();
        context!.translateBy(x: 0, y: self.size.height);
        context!.scaleBy(x: 1.0, y: -1.0);
        context!.draw(self.cgImage!, in: rect)
        context!.clip(to: rect, mask: self.cgImage!)
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let colorizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return colorizedImage!
    }
    func resize(x: CGFloat, y: CGFloat) -> UIImage {
        let size = CGSize(width: x, height: y)
        let scale = CGFloat(max(size.width/self.size.width,
                                size.height/self.size.height))
        let width:CGFloat  = self.size.width * scale
        let height:CGFloat = self.size.height * scale;
        
        let rr:CGRect = CGRect(x: 0, y: 0, width: width, height: height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0);
        self.draw(in: rr)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
}
