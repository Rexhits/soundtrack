//
//  MusicTheory.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/23/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation
import SwiftyJSON


struct TimeSignature: CustomStringConvertible {
    var lengthPerBeat: Int
    var beatsPerMeasure: Int
    var description = ""
    init(timeStamp: MusicTimeStamp, lengthPerBeat: Int, beatsPerMeasure: Int) {
        self.lengthPerBeat = lengthPerBeat
        self.beatsPerMeasure = beatsPerMeasure
        description = "\(lengthPerBeat)/\(beatsPerMeasure)"
    }
    var asJson: JSON {
        var json: JSON = [:]
        json["lengthPerBeat"].int = self.lengthPerBeat
        json["beatsPerMeasure"].int = self.beatsPerMeasure
        return json
    }
    init(json: JSON) {
        guard let lengthPerBeat = json["lengthPerBeat"].int, let beatsPerMeasure = json ["beatsPerMeasure"].int else {
            self.lengthPerBeat = 4
            self.beatsPerMeasure = 4
            return
        }
        self.lengthPerBeat = lengthPerBeat
        self.beatsPerMeasure = beatsPerMeasure
    }
}


struct RhythmPattern: CustomStringConvertible {
    // Velocity
    var sequence: [Int]
    // Timestamp
    var timeStamp: [MusicTimeStamp]
    
    var description: String {
        return String(describing: sequence)
    }
}

struct Measure: MusicalSequence {
    internal var content: BasicMusicalStructure = BasicMusicalStructure()
    init(notes: [NoteEvent], articulations: [Articulation]) {
        self.content.notes = notes
        self.content.articulations = articulations
    }
    init() {
        
    }
}


class Track: MusicalSequence {
    internal var content: BasicMusicalStructure = BasicMusicalStructure()
    var parser: MIDIParser!
    var trackIndex: Int!
    var instrumentView: UIView?
    var name: String!
    var type = PlaybackEngine.trackType.instrument
    var instrument: AVAudioUnitMIDIInstrument?
    var selectedNode: AVAudioUnit?
    var selectedUnit: AUAudioUnit?
    var selectedUnitDescription: AudioComponentDescription?
    var trackColor: UIColor?
    var selectedUnitPreset = [AUAudioUnitPreset]()
    var effects = [AVAudioUnitEffect]()
    let mixer = AVAudioMixerNode()
    
    init(parser: MIDIParser) {
        self.parser = parser
    }
    required init() {
        
    }
    init(trackType: PlaybackEngine.trackType) {
        type = trackType
        name = self.content.instrumentName
        if trackType == .instrument {
            instrument = AVAudioUnitSampler()
            if name == nil {
                name = instrument?.auAudioUnit.audioUnitName
            }
        } else {
            instrument = nil
        }
    }
    func addToPlaybackEngine(trackType: PlaybackEngine.trackType) {
        type = trackType
        name = self.content.instrumentName
        if trackType == .instrument {
            instrument = AVAudioUnitSampler()
            if name == nil {
                name = instrument?.auAudioUnit.audioUnitName
            }
        } else {
            instrument = nil
        }
    }

}



struct Articulation: CustomStringConvertible {
    var status: UInt8 = 0
    var timeStamp: MusicTimeStamp = 0
    var controllerNum:Int = 0
    var value:Int = 0
    var description: String {
        return String("Controller: \(controllerNum)\tValue: \(value)")
    }
    var asJson: JSON {
        var json: JSON = [:]
        json["status"].uInt8 = status
        json["controllerNum"].int = controllerNum
        json["timeStamp"].double = timeStamp
        json["value"].int = value
        return json
    }
    
    init(status: UInt8, timeStamp: MusicTimeStamp, controllerNum: Int, value: Int) {
        self.status = status
        self.timeStamp = timeStamp
        self.controllerNum = controllerNum
        self.value = value
    }
    
    init(json: JSON) {
        guard let status = json["status"].uInt8, let controllerNum = json["controllerNum"].int, let timeStamp = json["timeStamp"].double, let value = json["value"].int else {
            return
        }
        self.status = status
        self.timeStamp = timeStamp
        self.controllerNum = controllerNum
        self.value = value
    }
}


/// Basic Structure for NoteSequence
internal struct BasicMusicalStructure {
    var attachTo: MusicBlock?
    var instrumentName = ""
    var notes = [NoteEvent]()
    var tempo = 100
    var articulations = [Articulation]()
    var timeSignature = TimeSignature(timeStamp: 0, lengthPerBeat: 4, beatsPerMeasure: 4)
    var musicTrack: MusicTrack?
    var noteDistribution: [Int: [NoteEvent]] = [0:[NoteEvent](), 1:[NoteEvent](), 2:[NoteEvent](), 3:[NoteEvent](), 4:[NoteEvent](), 5:[NoteEvent](), 6:[NoteEvent](), 7:[NoteEvent](), 8:[NoteEvent](), 9:[NoteEvent](), 10:[NoteEvent](), 11: [NoteEvent]()]
    var sequenceType = 0
}



struct NoteEvent: Equatable, Comparable, CustomStringConvertible, CustomDebugStringConvertible {
    var timeStamp: MusicTimeStamp = 0 {
        didSet {
            timeRange = timeStamp ... timeStamp + duration
        }
    }
    var channel = 0
    var note = 0
    var velocity = 0
    var duration:MusicTimeStamp = 0
    var debugDescription: String {
        return String(note)
    }
    
    var timeRange = ClosedRange<MusicTimeStamp>.init(uncheckedBounds: (lower: 0, upper: 1))
    var asJson: JSON {
        var json: JSON = [:]
        json["pitchClass"].int = note % 12
        json["timeStamp"].double = timeStamp
        json["octave"].int = Int(note / 12)
        json["duration"].double = duration
        json["velocity"].int = velocity
        json["channel"].int = channel
        return json
    }
    
    init(json: JSON) {
        guard let pitchClass = json["pitchClass"].int, let timeStamp = json["timeStamp"].double, let octave = json["octave"].int, let duration = json["duration"].double, let velocity = json["velocity"].int, let channel = json["channel"].int else {
            return
        }
        self.note = pitchClass + 12 * octave
        self.channel = channel
        self.velocity = velocity
        self.duration = duration
        self.timeStamp = timeStamp
        self.timeRange =  timeStamp ... timeStamp + duration
    }
    
    var description: String {
        return String("\nTimeStamp:  \(timeStamp)\nNoteNum: \(note)\nVelocity: \(velocity)\nduration: \(duration)\nChannel: \(channel)")
    }
    init(timeStamp: MusicTimeStamp, channel: Int, note: Int, velocity: Int, duration: MusicTimeStamp) {
        self.timeStamp = timeStamp
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.duration = MusicTimeStamp(duration)
        self.timeRange = timeStamp ... timeStamp + duration
    }
    init(note: Int, velocity: Int, timeStamp: MusicTimeStamp, duration: MusicTimeStamp) {
        self.note = note
        self.velocity = velocity
        self.timeStamp = timeStamp
        self.duration = MusicTimeStamp(duration)
        self.timeRange = timeStamp ... timeStamp + duration
    }
    
    static func == (lhs: NoteEvent, rhs: NoteEvent) -> Bool {
        let equal = lhs.note == rhs.note
        return equal
    }
    static func ~= (lhs:NoteEvent, rhs: NoteEvent) -> Bool {
        // use remainder to extract the exact note number (0-11)
        let equalNote = lhs.note % 12 == rhs.note % 12
        let equalOctave = Int(lhs.note / 12) == Int(rhs.note / 12)
        return equalNote && equalOctave
    }
    
    static func < (lhs: NoteEvent, rhs: NoteEvent) -> Bool {
        return lhs.timeStamp < rhs.timeStamp
    }
}





