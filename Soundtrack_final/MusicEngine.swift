//
//  MusicEngine.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/18/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation


let csound = CsoundObj()

func updateScore() {
    
}


class MIDIParser {
    var sequencer: MusicSequence?
    var tempoTrack: MusicTrack?
    var tracks = [MusicTrack]()
    var trackCount: UInt32 = 0
    var tempo = [TempoInfo]()
    
    struct EventInfo {
        var timeStamp: MusicTimeStamp = 0
        var type: UInt32 = 0
        var data: UnsafeRawPointer?
        var dataSize: UInt32 = 0
    }
    
    struct TempoInfo {
        var timeStamp: MusicTimeStamp = 0
        var bpm: Int
    }
    
    init(url: NSURL) {
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
        var hasNext:DarwinBoolean = true
        var newInfo = EventInfo()
        var eventIterator: MusicEventIterator?
        NewMusicEventIterator(track, &eventIterator)
        while hasNext.boolValue {
            MusicEventIteratorNextEvent(eventIterator!)
            MusicEventIteratorGetEventInfo(eventIterator!, &newInfo.timeStamp, &newInfo.type, &newInfo.data, &newInfo.dataSize)
            switch newInfo.type {
            case 3:
                let pointer = newInfo.data!.bindMemory(to: ExtendedTempoEvent.self, capacity: Int(newInfo.dataSize))
                let mess = pointer.pointee
                tempo.append(TempoInfo(timeStamp: newInfo.timeStamp, bpm: Int(mess.bpm)))
            case 6:
                let pointer = newInfo.data!.bindMemory(to: MIDINoteMessage.self, capacity: Int(newInfo.dataSize))
                let mess = pointer.pointee
                print(mess)
            default:
                break
            }

            MusicEventIteratorHasNextEvent(eventIterator!, &hasNext)
        }
    }
}
