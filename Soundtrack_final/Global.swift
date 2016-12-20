//
//  Global.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox
import SwiftyJSON


var token = NSString()

let n: UInt8 = 0

func iteratorForTuple(tuple: Any) -> AnyIterator<Any> {
    return AnyIterator(Mirror(reflecting: tuple).children.lazy.map { $0.value }.makeIterator())
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
