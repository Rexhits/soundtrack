//
//  Global.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox



var token = NSString()

let n: UInt8 = 0

func iteratorForTuple(tuple: Any) -> AnyIterator<Any> {
    return AnyIterator(Mirror(reflecting: tuple).children.lazy.map { $0.value }.makeIterator())
}


func getURLInDocumentDirectoryWithFilename (filename: String) -> NSURL {
    let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentDirectory = path[0] as String
    let fullpath = "\(documentDirectory)/\(filename)"
    return NSURL(fileURLWithPath: fullpath)
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

internal class MIDISequencer {
    var sequencer: MusicSequence?
    internal var tempoTrack: MusicTrack?
    internal var tracks = [MusicTrack]()
    internal var timeSignature = TimeSignature(timeStamp: 0, lengthPerBeat: 4, beatsPerMeasure: 4)
    var tempo = 100
    internal struct EventInfo {
        var timeStamp: MusicTimeStamp = 0
        var type: UInt32 = 0
        var data: UnsafeRawPointer?
        var dataSize: UInt32 = 0
    }
    
    
    internal struct TimeSignatureEvents {
        var type: UInt8 = 0
        var unused1: UInt8 = 0
        var unused2: UInt8 = 0
        var unused3: UInt8 = 0
        var dataLength:UInt32 = 0
        // This sucks! Due to the returned tuple!
        var data = (n, n, n, n)
    }
    
    internal struct InstrumentNameEvents {
        var type: UInt8 = 0
        var unused1: UInt8 = 0
        var unused2: UInt8 = 0
        var unused3: UInt8 = 0
        var dataLength:UInt32 = 0
        // This sucks! Due to the returned tuple! 32 char for an instrument name should be enough...
        var data = (n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n)
    }
    
    init() {
        NewMusicSequence(&sequencer)
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

