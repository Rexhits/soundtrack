//
//  MusicSequence.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/5/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox

protocol MusicalSequence: CustomStringConvertible {
    var attachTo: MusicBlock? {get set}
    var musicTrack: MusicTrack? {get set}
    var content: BasicMusicalStructure {get set}
    var description: String {get}
    mutating func addNote(note: NoteEvent)
    mutating func addArticulation(articulation: Articulation)
    mutating func addSequence(sequence: MusicalSequence)
    mutating func appendSequence(inputSequence: MusicalSequence)
    func byMeasure() -> [Measure]
    func getNoteMatrix() -> String
    func getArticulationMatrix() -> String
}

extension MusicalSequence {
    var description: String {
        return String("\nInstrumentName:  \(instrumentName)\nTempo: \(tempo)\nTimeSignature: \(timeSignature)\nNotes: \(notes)\nArticulations: \(articulations)\n")
    }
    var trackNum: Int? {
        return nil
    }
    
    var musicTrack:MusicTrack? {
        get {return content.musicTrack}
        set {
            content.musicTrack = newValue
            print("MusicTrack set \(self.content.musicTrack)")
        }
    }
    var attachTo: MusicBlock? {
        get {return content.attachTo}
        set {
            content.attachTo = newValue!
            self.timeSignature = newValue!.timeSignature
            self.tempo = newValue!.tempo
        }
    }
    
    var notes: [NoteEvent] {
        get {return content.notes}
        set {content.notes = newValue}
    }
    
    var tempo: Int {
        get {return content.tempo}
        set {content.tempo = newValue}
    }
    
    var articulations: [Articulation] {
        get {return content.articulations}
        set {content.articulations = newValue}
    }
    
    var timeSignature: TimeSignature {
        get {return content.timeSignature}
        set {content.timeSignature = newValue}
    }
    
    var instrumentName: String {
        get {return content.instrumentName}
        set {content.instrumentName = newValue}
    }
    
    
    
    mutating func addNote(note: NoteEvent) {
        notes.append(note)
    }
    mutating func addArticulation(articulation: Articulation) {
        articulations.append(articulation)
    }
    mutating func addSequence(sequence: MusicalSequence) {
        for n in sequence.notes {
            self.addNote(note: n)
        }
        for a in sequence.articulations {
            self.addArticulation(articulation: a)
        }
    }
    func byMeasure() -> [Measure] {
        var sequence = [Measure]()
        var currentMeasure = Measure()
        var currentMeasureNum = 1
        let mesureLength = timeSignature.lengthPerBeat/timeSignature.beatsPerMeasure * 4
        if !notes.isEmpty {
            for i in notes {
                if i.timeStamp >= Double(mesureLength * currentMeasureNum) && i.timeStamp != 0 {
                    sequence.append(currentMeasure)
                    currentMeasureNum += 1
                    currentMeasure = Measure()
                    currentMeasure.addNote(note: i)
                } else {
                    currentMeasure.addNote(note: i)
                    currentMeasure.instrumentName = instrumentName
                    currentMeasure.tempo = tempo
                    currentMeasure.timeSignature = timeSignature
                }
            }
            sequence.append(currentMeasure)
            currentMeasureNum = 1
            currentMeasure = Measure()
        }
        if !articulations.isEmpty {
            for i in articulations {
                if i.timeStamp >= Double(mesureLength * currentMeasureNum) && i.timeStamp != 0 {
                    currentMeasureNum += 1
                    sequence[currentMeasureNum - 1].addArticulation(articulation: i)
                } else {
                    sequence[currentMeasureNum - 1].addArticulation(articulation: i)
                }
            }
            currentMeasureNum = 1
        }
        return sequence
    }
    
    func getNoteMatrix() -> String {
        /// OutputMartixString, Format: Channel, TimeStamp, Note, Velocity, Duration
        var output = [String]()
        for i in notes {
            output.append("\(String.init(format: "%2d", i.channel)) \t \(String.init(format: "%.2f", i.timeStamp)) \t \(String.init(format: "%3d", i.note)) \t \(String.init(format: "%3d", i.velocity)) \t \(String.init(format: "%.4f", i.duration))")
        }
        return output.joined(separator: "\n")
    }
    
    func getArticulationMatrix() -> String {
        var output = [String]()
        for i in articulations {
            output.append("\(i.status) \t \(String.init(format: "%.2f", i.timeStamp)) \t \(String.init(format: "%3d", i.controllerNum)) \t \(String.init(format: "%3d", i.value))")
        }
        return output.joined(separator: "\n")
    }
    func getNoteInterval() -> [Int] {
        var intervalList = [Int]()
        for i in 0 ..< notes.count - 1 {
            intervalList.append(notes[i + 1].note - notes[i].note)
        }
        return intervalList
    }
    
    mutating func appendSequence(inputSequence: MusicalSequence) {
        var endTime: MusicTimeStamp = 0
        if self.musicTrack != nil {
            endTime = getTrackLength(musicTrack: self.musicTrack!)
            print("EndTime: \(endTime)")
        }
        for var i in inputSequence.notes {
            i.timeStamp += endTime
            if self.musicTrack != nil {
                addNoteEvent(track: self.musicTrack!, note: i)
                addNote(note: i)
            }
        }
        for var i in inputSequence.articulations {
            i.timeStamp += endTime
            if self.musicTrack != nil {
                addControllerEvent(track: self.musicTrack!, event: i)
                addArticulation(articulation: i)
            }
        }
        
    }
    
    private func addNoteEvent(track: MusicTrack, note: NoteEvent) {
        var noteMess = MIDINoteMessage(channel: UInt8(note.channel), note: UInt8(note.note), velocity: UInt8(note.velocity), releaseVelocity: 0, duration: note.duration)
        let status = MusicTrackNewMIDINoteEvent(track, note.timeStamp, &noteMess)
        if status != OSStatus(noErr) {
            print("error adding Note \(status)")
        } else {
            print("new Note added: \(note)")
        }
    }
    
    private func addControllerEvent(track: MusicTrack, event: Articulation) {
        var messStatus = event.status
        switch messStatus {
        case 160 ... 175:
            messStatus = 161
        case 176 ... 201:
            messStatus = 177
        case 240 ... 255:
            messStatus = 241
        default:
            break
        }
        var ChannelMess = MIDIChannelMessage(status: event.status, data1: UInt8(event.controllerNum), data2: UInt8(event.value), reserved: 0)
        let status = MusicTrackNewMIDIChannelEvent(track, event.timeStamp, &ChannelMess)
        if status != OSStatus(noErr) {
            print("error adding Controller Message \(status)")
        } else {
            print("new Controller Message added: \(event)")
        }
    }
    private func getTrackLength(musicTrack:MusicTrack) -> MusicTimeStamp {
        
        //The time of the last music event in a music track, plus time required for note fade-outs and so on.
        var trackLength = MusicTimeStamp(0)
        var tracklengthSize = UInt32(0)
        let status = MusicTrackGetProperty(musicTrack,
                                           UInt32(kSequenceTrackProperty_TrackLength),
                                           &trackLength,
                                           &tracklengthSize)
        if status != OSStatus(noErr) {
            print("Error getting track length \(status)")
            return 0
        }
        print("track length is \(trackLength)")
        return trackLength
    }
}
