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

let Keys = ["C", "#C", "D", "#D", "E", "F", "#F", "G", "#G", "A", "#A", "B"]
let TimeSignatures = ["2/4", "3/4", "4/4", "6/8"]
let Tempo = (40 ... 220).map{String($0)}
let SequenceType = ["Rhythmic", "Melodic", "Bass", "Percussion"]
let noteLowerBound = 24
let noteUpperBound = 102

var currentUser: UserInfo?

final class ServerCommunicator: NSObject {
    static let shared = ServerCommunicator()
    let serverURL = "http://45.79.208.141/"
    let manager = AFHTTPSessionManager()
    override init() {
        super.init()
        getToken()
    }
    
    func getCurrentUser() {
        Server.get(api: "users/current", body: nil) { (response, err, errCode) in
            guard response != nil else {return}
            let res = response! as! JSONPackage
            currentUser = UserInfo(json: res)
        }
    }
    
    func getToken() {
        let token = Lockbox.unarchiveObject(forKey: "Token")
        if token != nil {
            manager.requestSerializer.setValue(token! as? String, forHTTPHeaderField: "Authorization")
        }
    }
    
    func get(url: String, body:JSONPackage?, completion: @escaping (Any?, Error?, Int?)->Void) {
        getToken()
        manager.get(url, parameters: nil, progress: nil, success: { (task:URLSessionDataTask, response: Any?) in
            completion(response, nil, nil)
        }) { (task: URLSessionDataTask?, err: Error) in
            if let res = task?.response as? HTTPURLResponse {
                completion(nil, err, res.statusCode)
            } else {
                completion(nil, nil, 404)
            }
        }
    }
    
    func get(api: String, body:JSONPackage?, completion: @escaping (Any?, Error?, Int?)->Void) {
        getToken()
        manager.get("\(serverURL)\(api)/", parameters: nil, progress: nil, success: { (task:URLSessionDataTask, response: Any?) in
            completion(response, nil, nil)
        }) { (task: URLSessionDataTask?, err: Error) in
            if let res = task?.response as? HTTPURLResponse {
                completion(nil, err, res.statusCode)
            } else {
                completion(nil, nil, 404)
            }
        }
    }
    func post(api: String, body:JSONPackage, completion: @escaping (Any?, Error?, Int?)->Void) {
        getToken()
        manager.post("\(serverURL)\(api)/", parameters: body, progress: nil, success: { (task, response) in
            completion(response, nil, nil)
        }) {(task, err) in
            if let res = task?.response as? HTTPURLResponse {
                completion(nil, err, res.statusCode)
            } else {
                completion(nil, nil, 404)
            }
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
    
    func uploadBlock(block: MusicBlock, billboard: String, completion: @escaping (JSONPackage?, Error?, Int?)->Void) {
        getToken()
        let body = ["title": block.name, "onboard": billboard]
        let midiFile = block.getSequenceData()!
        
        manager.post("\(serverURL)musicblock/", parameters: body, constructingBodyWith: { (formData: AFMultipartFormData) in
            do {
                let jsonFile = try block.asJSON.rawData()
                formData.appendPart(withFileData: jsonFile, name: "jsonFile", fileName: "\(block.name).json", mimeType: "application/json")
            } catch {
                print(error.localizedDescription)
            }
            formData.appendPart(withFileData: midiFile, name: "midiFile", fileName: "\(block.name).mid", mimeType: "audio/midi")
            if let af = block.audioFile {
                do {
                    let url = URL(fileURLWithPath: af)
                    let audioFile = try Data.init(contentsOf: url)
                    formData.appendPart(withFileData: audioFile, name: "audioFile", fileName: "\(block.name).mp3", mimeType: "audio/midi")
                } catch {
                    print("error reading audio file")
                }
            }
            for i in block.parsedTracks {
                let instPreset = i.getAUStates()
                for n in instPreset {
                    if n.key == "instState" {
                        let path = STFileManager.shared.getTempDir().appendingPathComponent("track_\(i.trackIndex!).aupreset")
                        (n.value as! NSDictionary).write(to: path, atomically: true)
                        do {
                            try formData.appendPart(withFileURL: path, name: "instStatus", fileName: "\(path.fileName()).aupreset", mimeType: "application/xml")
                        } catch {
                            print(error.localizedDescription)
                        }
//                        let aupreset = try! PropertyListSerialization.data(fromPropertyList: n.value, format: .xml, options: 0)
                        
//                        formData.appendPart(withFileData: aupreset, name: "instStatus", fileName: "track_\(i.trackIndex!).aupreset", mimeType: "application/xml")
                    } else {
                        let value =  n.value as! [[String: Any]]
                        for v in value.enumerated() {
                            let path = STFileManager.shared.getTempDir().appendingPathComponent("track_\(i.trackIndex!)_\(v.offset).aupreset")
                            (v.element as NSDictionary).write(to: path, atomically: true)
                            do {
                                try formData.appendPart(withFileURL: path, name: "fxStatus", fileName: "\(path.fileName()).aupreset", mimeType: "application/xml")
                            } catch {
                                print(error.localizedDescription)
                            }
//                            let aupreset = try! PropertyListSerialization.data(fromPropertyList: v.element, format: .xml, options: 0)
//                            formData.appendPart(withFileData: aupreset, name: "fxStatus", fileName: "track_\(i.trackIndex!)_\(v.offset).aupreset", mimeType: "application/xml")
                        }
                    }
                }
            }
        }, progress: nil, success: { (task:URLSessionDataTask, response: Any?) in
            completion(response as? JSONPackage, nil, nil)
        }) { (task: URLSessionDataTask?, err: Error) in
            let response = task!.response as! HTTPURLResponse
            completion(nil, err, response.statusCode)
        }
    }
    
    func editBlock(block: MusicBlock, completion: @escaping (JSONPackage?, Error?, Int?)->Void) {
        let body = ["title": block.name]
        let midiFile = block.getSequenceData()!
        let jsonFile = try! block.asJSON.rawData()
        var err: NSError?
        let request = manager.requestSerializer.multipartFormRequest(withMethod: "PATCH", urlString: block.url!, parameters: body, constructingBodyWith: { (formData: AFMultipartFormData) in
            formData.appendPart(withFileData: midiFile, name: "midiFile", fileName: "\(block.name).mid", mimeType: "audio/midi")
            formData.appendPart(withFileData: jsonFile, name: "jsonFile", fileName: "\(block.name).json", mimeType: "application/json")
            for i in block.parsedTracks {
                let instPreset = i.getAUStates()
                for n in instPreset {
                    if n.key == "instState" {
                        let aupreset = try! PropertyListSerialization.data(fromPropertyList: n.value, format: .xml, options: 0)
                        formData.appendPart(withFileData: aupreset, name: "instStatus", fileName: "track_\(i.trackIndex!).aupreset", mimeType: "application/xml")
                    } else {
                        let value =  n.value as! [[String: Any]]
                        for v in value.enumerated() {
                            let aupreset = try! PropertyListSerialization.data(fromPropertyList: v.element, format: .xml, options: 0)
                            formData.appendPart(withFileData: aupreset, name: "fxStatus", fileName: "track_\(i.trackIndex!)_\(v.offset).aupreset", mimeType: "application/xml")
                        }
                    }
                }
            }
        }, error: &err)
        
        
        let dataTask = manager.dataTask(with: request as URLRequest) { (response: URLResponse, object, err) in
            let res = object ?? nil
            completion(res as! JSONPackage?, err, nil)
        }
        dataTask.resume()
    }
}

let Server = ServerCommunicator.shared

let n: UInt8 = 0

func iteratorForTuple(tuple: Any) -> AnyIterator<Any> {
    return AnyIterator(Mirror(reflecting: tuple).children.lazy.map { $0.value }.makeIterator())
}

extension Int
{
    static func random(range: CountableClosedRange<Int> ) -> Int
    {
        var offset = 0
        
        if range.lowerBound < 0   // allow negative ranges
        {
            offset = abs(range.lowerBound)
        }
        
        let mini = UInt32(range.lowerBound + offset)
        let maxi = UInt32(range.upperBound   + offset)
        
        return Int(mini + arc4random_uniform(maxi - mini)) - offset
    }
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
    
    func getIDFromURL() -> Int? {
        let split = self.characters.split(separator: "/").map(String.init)
        if let i = Int(split.last!) {
            return i
        } else {
            return nil
        }
    }
}

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfYear], from: date, to: self).weekOfYear ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
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




public extension Sequence where Iterator.Element: Hashable {
    var uniqueElements: [Iterator.Element] {
        return Array(
            Set(self)
        )
    }
    
    func frequencies() -> [(Self.Iterator.Element,Int)] {
        
        var frequency: [Self.Iterator.Element:Int] = [:]
        
        for x in self {
            frequency[x] = (frequency[x] ?? 0) + 1
        }
        
        return frequency.sorted { $0.1 > $1.1 }
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

extension URL {
    func fileName() -> String {
        if let url = NSURL(fileURLWithPath: self.path).deletingPathExtension?.lastPathComponent {
            return url
        } else {
            return ""
        }
    }
    func fileExtension() -> String {
        if let ext = NSURL(fileURLWithPath: self.path).pathExtension {
            return ext
        } else {
            return ""
        }
    }
}

extension AudioComponentDescription: Equatable {
    public static func ==(lhs: AudioComponentDescription, rhs: AudioComponentDescription) -> Bool {
        return lhs.componentType == rhs.componentType && lhs.componentSubType == rhs.componentSubType && lhs.componentFlags == rhs.componentFlags && lhs.componentFlagsMask == rhs.componentFlagsMask && lhs.componentManufacturer == rhs.componentManufacturer
    }
    var asJson: JSON {
        var json: JSON = [:]
        json["componentType"].uInt32 = self.componentType
        json["componentSubType"].uInt32 = self.componentSubType
        json["componentFlags"].uInt32 = self.componentFlags
        json["componentFlagsMask"].uInt32 = self.componentFlagsMask
        json["componentManufacturer"].uInt32 = self.componentManufacturer
        return json
    }
}

extension UIColor {
    var asJson: JSON {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        var json: JSON = [:]
        json["r"].float = Float(red)
        json["g"].float = Float(green)
        json["b"].float = Float(blue)
        json["a"].float = Float(alpha)
        return json
    }
    
    public convenience init?(json: JSON) {
        guard let r = json["r"].float, let g = json["g"].float, let b = json["b"].float, let a = json["a"].float else {
            return nil
        }
        self.init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    }
    
    static func hexStringToUIColor (hex: String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
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

extension UIColor {
    static func randomColor() -> UIColor {
        let hue = CGFloat(arc4random() & 256 / 256)
        let saturation = CGFloat(arc4random() & 256 / 256) + 0.5
        let brightness = CGFloat(arc4random() & 256 / 256) + 0.5
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}


class ParkBenchTimer {
    
    let startTime:CFAbsoluteTime
    var endTime:CFAbsoluteTime?
    
    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()
        
        return duration!
    }
    
    var duration:CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}

extension FileManager {
    func listFiles(path: String) -> [String] {
        let baseurl: URL = URL(fileURLWithPath: path)
        var urls = [String]()
        enumerator(atPath: path)?.forEach({ (e) in
            guard let s = e as? String else { return }
            let relativeURL = URL(fileURLWithPath: s, relativeTo: baseurl)
            let url = relativeURL.path
            urls.append(url)
        })
        return urls
    }
}



