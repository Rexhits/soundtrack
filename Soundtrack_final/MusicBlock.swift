//
//  MusicBlock.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/5/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox

class MusicBlock: MIDIParser {
    var name: String
    var composedBy: String
    override var description: String {
        return "Name: \(name)\nComposedBy: \(composedBy)\nTempo: \(tempo)\nTimeSignature: \(timeSignature)\nHasTempoTrack: \(tempoTrack != nil)\nNumberOfTracks: \(tracks.count)"
    }
    var length = MusicTimeStamp()
    init(name: String, composedBy: String) {
        self.name = name
        self.composedBy = composedBy
        super.init()
    }
    init(name: String, composedBy: String, midiFile: NSURL) {
        self.name = name
        self.composedBy = composedBy
        super.init(url: midiFile)
        super.parse()
    }
    func addTracks(tracks: [MusicalSequence]) {
        for i in tracks {
            self.tempo = i.tempo
            self.timeSignature = i.timeSignature
            let track = newTrack()
            for n in i.notes {
                addNoteEvent(track: track, note: n)
            }
            for a in i.articulations {
                addControllerEvent(track: track, event: a)
            }
            self.tracks.append(track)
        }
        getTempoTrack()
        addTempoEvent(bpm: Float64(self.tempo), startAt: 0)
        addTimeSignatureEvent(timeSignature: self.timeSignature, startAt: 0)
        self.parsedTracks = tracks
    }
    func addTrack(track: MusicalSequence) {
        var localtrack = track
        self.tempo = localtrack.tempo
        self.timeSignature = localtrack.timeSignature
        let newtrack = newTrack()
        for n in track.notes {
            addNoteEvent(track: newtrack, note: n)
        }
        for a in track.articulations {
            addControllerEvent(track: newtrack, event: a)
        }
        self.tracks.append(newtrack)
        addTempoEvent(bpm: Float64(self.tempo), startAt: 0)
        localtrack.musicTrack = newtrack
        self.parsedTracks.append(localtrack)
    }
    
    
    // Method to add a new track
    private func newTrack() -> MusicTrack {
        // Creating a new track
        var newTrack: MusicTrack?
        // Add to the sequencer
        let status = MusicSequenceNewTrack(sequencer!, &newTrack)
        if status != OSStatus(noErr) {
            print("error creating track \(status)")
        } else {
            print("new track created")
        }
        return newTrack!
    }
    private func getTempoTrack(){
        // Get the tempo track and store it to "tempoTrack"
        let status = MusicSequenceGetTempoTrack(sequencer!, &self.tempoTrack)
        if status != OSStatus(noErr) {
            print("error getting tempo track \(status)")
        } else {
            print("got tempo track")
        }
    }
    
    private func addTempoEvent(bpm: Float64, startAt: MusicTimeStamp) {
        if tempoTrack != nil {
            if startAt == 0 {
                // Clear the tempo track if the event start at the beginning, in case there're multiple tempo event there
                MusicTrackClear(tempoTrack!, 0, 1)
            }
            // Add event to tempo track
            let status = MusicTrackNewExtendedTempoEvent(self.tempoTrack!, startAt, bpm)
            if status != OSStatus(noErr) {
                print("error adding tempo \(status)")
            } else {
                print("new tempo added: \(bpm), at timestamp: \(startAt)")
            }
        } else {
            print("tempo track not found")
        }
    }
    // Method to add time signature event
    private func addTimeSignatureEvent(timeSignature: TimeSignature, startAt: MusicTimeStamp) {
        // Convert raw denominator into required value (a negative power of 2: 2 = quarter note, 3 = eighth, 4 = 16 etc)
        let numerator = UInt8(timeSignature.beatsPerMeasure)
        let denominatorOut = UInt8(log2f(Float(timeSignature.lengthPerBeat)))
        if tempoTrack != nil {
            var event = MIDIMetaEvent()
            var data = (numerator, denominatorOut, UInt8(18), UInt8(08))
            event.metaEventType = 88
            event.dataLength = 4
            // Not Sure...
            memcpy(&event.data, &data, 4)
            let status = MusicTrackNewMetaEvent(self.tempoTrack!, 0, &event)
            if status != OSStatus(noErr) {
                print("error adding time signature \(status)")
            } else {
                print("new timesignature added: \(timeSignature), at timestamp:\(startAt)")
            }
        } else {
            print("tempo track not found")
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
    
    
    
    // Save the midifile to somewhere
    func saveMIDIFile (fileURL: NSURL) {
        let typeId = MusicSequenceFileTypeID.init(rawValue: 1835623529)
        
        let fileFlag = MusicSequenceFileFlags.init(rawValue: 1)
        let status = MusicSequenceFileCreate(sequencer!, fileURL, typeId!, fileFlag, 0)
        if status != OSStatus(noErr) {
            print("error saving midi file \(status)")
        } else {
            print("file saved at \(fileURL)")
        }
        
    }
    func getSequencer() -> MusicSequence? {
        return self.sequencer
    }
    
    func getSequenceData() -> Data? {
        var status = OSStatus(noErr)
        var cfdata: Unmanaged<CFData>?
        status = MusicSequenceFileCreateData(self.sequencer!, .midiType, .eraseFile, 480, &cfdata)
        if status != noErr {
            print("ERROR CREATING DATA \(status)")
            return nil
        }
        let data = cfdata!.takeUnretainedValue()
        cfdata?.release()
        return data as Data
    }
    
}
