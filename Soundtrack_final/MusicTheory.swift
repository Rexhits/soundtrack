//
//  MusicTheory.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/23/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox



struct TimeSignature: CustomStringConvertible {
    var lengthPerBeat: Int
    var beatsPerMeasure: Int
    var description = ""
    init(timeStamp: MusicTimeStamp, lengthPerBeat: Int, beatsPerMeasure: Int) {
        self.lengthPerBeat = lengthPerBeat
        self.beatsPerMeasure = beatsPerMeasure
        description = "\(lengthPerBeat)/\(beatsPerMeasure)"
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


/// Basic Structure for NoteSequence
internal struct BasicMusicalStructure {
    var attachTo: MusicBlock?
    var instrumentName = ""
    var notes = [NoteEvent]()
    var tempo = 100
    var articulations = [Articulation]()
    var timeSignature = TimeSignature(timeStamp: 0, lengthPerBeat: 4, beatsPerMeasure: 4)
    var musicTrack: MusicTrack?
}



struct NoteEvent: Equatable, Comparable, CustomStringConvertible, CustomDebugStringConvertible {
    var timeStamp: MusicTimeStamp = 0
    var channel = 0
    var note = 0
    var velocity = 0
    var duration:Float = 0
    var debugDescription: String {
        return String(note)
    }
    var description: String {
        return String("\nTimeStamp:  \(timeStamp)\nNoteNum: \(note)\nVelocity: \(velocity)\nduration: \(duration)\nChannel: \(channel)")
    }
    init(timeStamp: MusicTimeStamp, channel: Int, note: Int, velocity: Int, duration: Float) {
        self.timeStamp = timeStamp
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.duration = duration
    }
    init(note: Int, velocity: Int, timeStamp: MusicTimeStamp, duration: Float) {
        self.note = note
        self.velocity = velocity
        self.timeStamp = timeStamp
        self.duration = duration
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





