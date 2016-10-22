//
//  MusicEngine.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/18/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation


let csound = CsoundObj()




class MIDIParser {
    var sequencer: MusicSequence?
    var tempoTrack: MusicTrack?
    var tracks = [MusicTrack]()
    var timeSignature = [TimeSignature.init(timeStamp: 0, lengthPerBeat: 4, beatsPerMeasure: 4)]
    var tempo = [TempoInfo]()
    var parsedTracks = [Track]()
    
    struct EventInfo {
        var timeStamp: MusicTimeStamp = 0
        var type: UInt32 = 0
        var data: UnsafeRawPointer?
        var dataSize: UInt32 = 0
    }
    
    
    
    struct TimeSignatureEvents {
        var type: UInt8 = 0
        var unused1: UInt8 = 0
        var unused2: UInt8 = 0
        var unused3: UInt8 = 0
        var dataLength:UInt32 = 0
        // This sucks! Due to the returned tuple!
        var data = (n, n, n, n)
    }
    
    struct InstrumentNameEvents {
        var type: UInt8 = 0
        var unused1: UInt8 = 0
        var unused2: UInt8 = 0
        var unused3: UInt8 = 0
        var dataLength:UInt32 = 0
        // This sucks! Due to the returned tuple! 32 char for an instrument name should be enough...
        var data = (n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n, n)
    }
    
    struct TempoInfo {
        var timeStamp: MusicTimeStamp = 0
        var bpm: Int
    }
    
    struct NoteEvent {
        var timeStamp: MusicTimeStamp = 0
        var channel = 0
        var note = 0
        var velocity = 0
        var duration:Double = 0
    }
    
    struct TimeSignature {
        var timeStamp: MusicTimeStamp = 0
        var lengthPerBeat = 4
        var beatsPerMeasure = 4
        var description = ""
        init(timeStamp: MusicTimeStamp, lengthPerBeat: Int, beatsPerMeasure: Int) {
            description = "\(lengthPerBeat)/\(beatsPerMeasure)"
        }
    }
    struct Measure {
        var notes = [NoteEvent]()
    }
    
    struct Track {
        var instrumentName = ""
        var measures = [Measure]()
        var timeSignature = [TimeSignature]()
        private var currentMeasure = Measure()
        private var currentMeasureNum: Int = 1
        private var parser: MIDIParser
        init(parser: MIDIParser) {
            self.parser = parser
            self.timeSignature = parser.timeSignature
        }
        mutating func addNote(note: NoteEvent) {
            if note.timeStamp >= MusicTimeStamp(currentMeasureNum * self.timeSignature[0].beatsPerMeasure) {
                measures.append(currentMeasure)
                currentMeasure.notes.removeAll()
                currentMeasure.notes.append(note)
                currentMeasureNum += 1
            } else {
                currentMeasure.notes.append(note)
            }
        }
        mutating func finishAddingNote() {
            if !currentMeasure.notes.isEmpty {
                measures.append(currentMeasure)
                self.parser.parsedTracks.append(self)
            }
            currentMeasure.notes.removeAll()
            currentMeasureNum = 1
        }
        
    }
    
    
    init(url: NSURL) {
        var trackCount: UInt32 = 0
        NewMusicSequence(&sequencer)
        MusicSequenceFileLoad(sequencer!, url, .midiType, .smf_PreserveTracks)
        MusicSequenceGetTrackCount(sequencer!, &trackCount)
        MusicSequenceGetTempoTrack(sequencer!, &tempoTrack)
        for i in 1 ..< trackCount {
            var track: MusicTrack?
            MusicSequenceGetIndTrack(sequencer!, i, &track)
            tracks.append(track!)
        }
    }
    
    
    func getInfo(track: MusicTrack) {
        var newTrack = Track(parser: self)
        var hasCurrent: DarwinBoolean = true
        var hasNext:DarwinBoolean = true
        var newInfo = EventInfo()
        var eventIterator: MusicEventIterator?
        NewMusicEventIterator(track, &eventIterator)
        while hasNext.boolValue && hasCurrent.boolValue {
            MusicEventIteratorHasCurrentEvent(eventIterator!, &hasCurrent)
            
            MusicEventIteratorGetEventInfo(eventIterator!, &newInfo.timeStamp, &newInfo.type, &newInfo.data, &newInfo.dataSize)
            switch newInfo.type {
            case 3:
                // Tempo Message
                let pointer = newInfo.data!.bindMemory(to: ExtendedTempoEvent.self, capacity: Int(newInfo.dataSize))
                let mess = pointer.pointee
                tempo.append(TempoInfo(timeStamp: newInfo.timeStamp, bpm: Int(mess.bpm)))
            case 5:
                // Meta Message
                let pointer = newInfo.data!.bindMemory(to: MIDIMetaEvent.self, capacity: Int(newInfo.dataSize))
                let mess = pointer.pointee
                switch mess.metaEventType {
                case 4:
                    // Instrument name Meta
                    var name = ""
                    let ptr = newInfo.data!.bindMemory(to: InstrumentNameEvents.self, capacity: Int(newInfo.dataSize))
                    let mess = ptr.pointee
                    for (i,v) in iteratorForTuple(tuple: mess.data).enumerated() {
                        let index: Int = i
                        let value: UInt8 = v as! UInt8
                        if index < Int(mess.dataLength) {
                            name.append(Character(UnicodeScalar(value)))
                        }
                    }
                    newTrack.instrumentName = name
                case 88:
                    // Time Signature Meta
                    self.timeSignature.removeAll()
                    let ptr = newInfo.data!.bindMemory(to: TimeSignatureEvents.self, capacity: Int(newInfo.dataSize))
                    let mess = ptr.pointee
                    let lengthPerBeat = Int(mess.data.0)
                    // Time signature's Denominator is stored in "powers of 2", use bitwise left shift operatorion(<<) is more efficient
                    let beatsPerMeasure = 2 << (Int(mess.data.1) - 1)
                    self.timeSignature.append(TimeSignature(timeStamp:newInfo.timeStamp, lengthPerBeat: lengthPerBeat, beatsPerMeasure: beatsPerMeasure))
                default:
                    break
                }
            case 6:
                // Note Message
                let pointer = newInfo.data!.bindMemory(to: MIDINoteMessage.self, capacity: Int(newInfo.dataSize))
                let mess = pointer.pointee
                let noteEvent = NoteEvent(timeStamp: newInfo.timeStamp, channel: Int(mess.channel), note: Int(mess.note), velocity: Int(mess.velocity), duration: Double(mess.duration))
                newTrack.addNote(note: noteEvent)
            default:
                break
            }
            
            MusicEventIteratorHasNextEvent(eventIterator!, &hasNext)
            MusicEventIteratorNextEvent(eventIterator!)
        }
        newTrack.finishAddingNote()
        
    }
    
}
