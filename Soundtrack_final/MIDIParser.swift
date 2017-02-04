//
//  MusicEngine.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/18/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation

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

internal class MIDIParser: MIDISequencer, CustomStringConvertible {
    var parsedTempoTrack: Track?
    var parsedTracks = [MusicalSequence]()
    var description: String {
        return "Tempo: \(tempo)\nTimeSignature: \(timeSignature)\nHasTempoTrack: \(tempoTrack != nil)\nTempoTrackParsed: \(parsedTempoTrack != nil)\nParsedTracks: \(parsedTracks.count)-\(tracks.count)"
    }
    
    override init() {
        super.init()
        NewMusicSequence(&sequencer)
    }
    
    init(url: URL) {
        super.init()
        var trackCount: UInt32 = 0
        NewMusicSequence(&sequencer)
        MusicSequenceFileLoad(sequencer!, url as CFURL, .midiType, .smf_PreserveTracks)
        MusicSequenceGetTrackCount(sequencer!, &trackCount)
        MusicSequenceGetTempoTrack(sequencer!, &tempoTrack)
        guard trackCount > 1 else {
            var track: MusicTrack?
            MusicSequenceGetIndTrack(sequencer!, 0, &track)
            tracks.append(track!)
            return
        }
        for i in 0 ..< trackCount {
            var track: MusicTrack?
            MusicSequenceGetIndTrack(sequencer!, i, &track)
            tracks.append(track!)
        }

    }
    
    init(data: Data) {
        super.init()
        var trackCount: UInt32 = 0
        NewMusicSequence(&sequencer)
        MusicSequenceFileLoadData(sequencer!, data as CFData, .midiType, .smf_PreserveTracks)
        MusicSequenceGetTrackCount(sequencer!, &trackCount)
        MusicSequenceGetTempoTrack(sequencer!, &tempoTrack)
        
        guard trackCount > 1 else {
            var track: MusicTrack?
            MusicSequenceGetIndTrack(sequencer!, 0, &track)
            tracks.append(track!)
            return
        }
        
        for i in 0 ..< trackCount {
            var track: MusicTrack?
            MusicSequenceGetIndTrack(sequencer!, i, &track)
            tracks.append(track!)
        }
    }
    
    func parse() {
        if tempoTrack != nil {
            self.parsedTempoTrack = getInfo(track: tempoTrack!)
        }
        for i in tracks {
            if let newTrack = getInfo(track: i) {
                self.parsedTracks.append(newTrack)
            }
        }
        for i in 0 ..< parsedTracks.count {
            parsedTracks[i].musicTrack = tracks[i]
        }
    }
    
    private func getInfo(track: MusicTrack) -> Track?{
        var newTrack = Track(parser: self)
        var hasCurrent: DarwinBoolean = true
        var hasNext:DarwinBoolean = true
        var newInfo = EventInfo()
        var eventIterator: MusicEventIterator?
        var noteCount = 0
        NewMusicEventIterator(track, &eventIterator)
        while hasNext.boolValue && hasCurrent.boolValue {
            MusicEventIteratorHasCurrentEvent(eventIterator!, &hasCurrent)
            MusicEventIteratorGetEventInfo(eventIterator!, &newInfo.timeStamp, &newInfo.type, &newInfo.data, &newInfo.dataSize)
            switch newInfo.type {
            case 3:
                // Tempo Message
                let pointer = newInfo.data!.bindMemory(to: ExtendedTempoEvent.self, capacity: Int(newInfo.dataSize))
                let mess = pointer.pointee
                tempo = Int(mess.bpm)
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
                    let ptr = newInfo.data!.bindMemory(to: TimeSignatureEvents.self, capacity: Int(newInfo.dataSize))
                    let mess = ptr.pointee
                    let beatsPerMeasure = Int(mess.data.0)
                    // Time signature's Denominator is stored in "powers of 2", use bitwise left shift operatorion(<<) is more efficient
                    let lengthPerBeat = 2 << (Int(mess.data.1) - 1)
                    self.timeSignature = TimeSignature(timeStamp:newInfo.timeStamp, lengthPerBeat: lengthPerBeat, beatsPerMeasure: beatsPerMeasure)
                default:
                    break
                }
            case 6:
                // Note Message
                let pointer = newInfo.data!.bindMemory(to: MIDINoteMessage.self, capacity: Int(newInfo.dataSize))
                let mess = pointer.pointee
                let noteEvent = NoteEvent(timeStamp: newInfo.timeStamp, channel: Int(mess.channel), note: Int(mess.note), velocity: Int(mess.velocity), duration: MusicTimeStamp(mess.duration))
                newTrack.addNote(note: noteEvent)
                noteCount += 1
            case 7:
                // Channel Meassage
                let pointer = newInfo.data!.bindMemory(to: MIDIChannelMessage.self, capacity: Int(newInfo.dataSize))
                var mess = pointer.pointee
                let messStatus = mess.status
                switch messStatus {
                case 160 ... 175:
                    mess.status = 161
                case 176 ... 201:
                    mess.status = 177
                case 240 ... 255:
                    mess.status = 241
                default:
                    break
                }
                MusicEventIteratorSetEventInfo(eventIterator!, 7, &mess)
                newTrack.addArticulation(articulation: Articulation(status: mess.status, timeStamp: newInfo.timeStamp, controllerNum: Int(mess.data1), value: Int(mess.data2)))
            default:
                break
            }
            MusicEventIteratorHasNextEvent(eventIterator!, &hasNext)
            MusicEventIteratorNextEvent(eventIterator!)
            
        }
        newTrack.timeSignature = timeSignature
        newTrack.tempo = tempo
        if noteCount > 0 {
            return newTrack
        } else {
            MusicSequenceDisposeTrack(sequencer!, track)
            return nil
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






