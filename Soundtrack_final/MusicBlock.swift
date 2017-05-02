//
//  MusicBlock.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/5/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox
import SwiftyJSON

class MusicBlock: MIDIParser {
    var name: String = ""
    var composedBy: String = ""
    override var description: String {
        return "Name: \(name)\nComposedBy: \(composedBy)\nTempo: \(tempo)\nTimeSignature: \(timeSignature)\nHasTempoTrack: \(tempoTrack != nil)\nNumberOfTracks: \(tracks.count)"
    }
    var length = MusicTimeStamp()
    var createdAt: Date!
    var midiFileUrl = URL(string: "")
    var url: String?
    var presetLoaded = false
    var key = 0
    var jsonFile: JSON!
    var audioFile: String?
    
    
    var asJSON: JSON {
        var json: JSON = [:]
        json["title"].string = self.name
        json["tempo"].int = self.tempo
        json["composedBy"].string = self.composedBy
        json["timeSig"] = self.timeSignature.asJson
        json["key"].int = self.key
        json["tracks"].arrayObject = self.parsedTracks.map{$0.getChannelSettings()}
        return json
    }
    
    override init() {
        self.name = "default"
        self.composedBy = "user"
        self.createdAt = Date()
        super.init()
    }
    
    init(name: String, composedBy: String) {
        self.name = name
        self.composedBy = composedBy
        super.init()
        createdAt = Date()
    }
    init(name: String, composedBy: String, midiFile: URL) {
        self.name = name
        self.composedBy = composedBy
        super.init(url: midiFile)
        super.parse()
        createdAt = Date()
        midiFileUrl = midiFile
    }
    
    init(jsonFile: Data, midiFile: Data) {
        let json = JSON.init(data: jsonFile)
        super.init(data: midiFile)
        loadData(json: json)
        
        super.parse()
        
    }
    
    init(clip: Clip) {
        super.init(data: clip.midiData! as Data)
        super.parse()
        self.tempo = Int(clip.tempo)
        let timeSig = clip.timeSignature?.components(separatedBy: "/")
        self.timeSignature = TimeSignature(timeStamp: 0, lengthPerBeat: Int(timeSig!.first!)!, beatsPerMeasure: Int(timeSig!.last!)!)
        self.key = Int(clip.key)
//        let trackDataSet = clip.hasTracks!.map{$0 as! TrackData}
//        for i in trackDataSet.enumerated() {
//            self.parsedTracks[i.offset].mixer.volume = i.element.volume
//            self.parsedTracks[i.offset].mixer.pan = i.element.pan
//        }
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
        self.parsedTracks = tracks as! [Track]
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
        self.parsedTracks.append(localtrack as! Track)
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
    
    func addTempoEvent(bpm: Float64, startAt: MusicTimeStamp) {
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
    func addTimeSignatureEvent(timeSignature: TimeSignature, startAt: MusicTimeStamp) {
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
    func addNoteEvent(track: MusicTrack, note: NoteEvent) {
        var noteMess = MIDINoteMessage(channel: 0, note: UInt8(note.note), velocity: UInt8(note.velocity), releaseVelocity: 0, duration: Float32(note.duration))
        let status = MusicTrackNewMIDINoteEvent(track, note.timeStamp, &noteMess)
        if status != OSStatus(noErr) {
            print("error adding Note \(status)")
        } else {
//            print("new Note added: \(note)")
        }
    }
    
    func addNoteEvent(trackNum: Int, note: NoteEvent) {
        addNoteEvent(track: self.tracks[trackNum], note: note)
        self.parsedTracks[trackNum].addNote(note: note)
    }
    
    
    func addControllerEvent(track: MusicTrack, event: Articulation) {
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
    func saveMIDIFile (fileURL: URL) -> URL?{
        let typeId = MusicSequenceFileTypeID.init(rawValue: 1835623529)
        
        let fileFlag = MusicSequenceFileFlags.init(rawValue: 1)
        let status = MusicSequenceFileCreate(sequencer!, fileURL as CFURL, typeId!, fileFlag, 0)
        if status != OSStatus(noErr) {
            print("error saving midi file \(status)")
            return fileURL
        } else {
            print("file saved at \(fileURL)")
            return nil
        }
        
    }
    func getSequencer() -> MusicSequence? {
        return self.sequencer
    }
    
    func getSequenceData() -> Data? {
        var trackCount:UInt32 = 0
        MusicSequenceGetTrackCount(sequencer!, &trackCount)
        print(trackCount)
        var status = OSStatus(noErr)
        var cfdata: Unmanaged<CFData>?
        status = MusicSequenceFileCreateData(self.sequencer!, .midiType, .eraseFile, 480, &cfdata)
        if status != noErr {
            print("ERROR CREATING DATA \(status)")
            return nil
        }
        let data = cfdata!.takeRetainedValue()
//        cfdata?.release()
        return data as Data
    }
    
    func saveJson() {
        let path = getURLInDocumentDirectoryWithFilename(filename: "\(self.name).json")
        print(path)
        do {
            let data = try self.asJSON.rawData()
            try data.write(to: path)
        } catch {
            print("Error creating data")
        }
        
    }
    
    func selectRange(start: MusicTimeStamp, length: MusicTimeStamp) -> MusicBlock {
        let newBlock = self
        let blockLength = newBlock.getBlockLength()
        var end = start + length
        if end >= blockLength {
            end = blockLength
        }
        let range = start ..< start + length
        for var i in newBlock.parsedTracks {
            i.notes = i.notes.filter{range.contains($0.timeStamp)}
            for n in 0 ..< i.notes.count {
                i.notes[n].timeStamp -= start
            }
        }
        let cutLeft = 0 ... start
        let cutRight = end ... blockLength
        
        for i in newBlock.tracks {
            MusicTrackCut(i, cutRight.lowerBound, cutRight.upperBound)
            MusicTrackCut(i, cutLeft.lowerBound, cutLeft.upperBound)
        }
        return newBlock
    }
//    func loadData() {
//        let dir = getURLInDocumentDirectoryWithFilename(filename: self.name)
//        let jsonPath = dir.appendingPathComponent("\(self.name).json")
//        do {
//            let jsonData = try Data.init(contentsOf: jsonPath, options: .dataReadingMapped)
//            let json = JSON.init(data: jsonData, options: .allowFragments, error: nil)
//            guard let tracks = json["tracks"].arrayObject, let composedBy = json["composedBy"].string, let name = json["title"].string, let tempo = json["tempo"].int else {
//                return
//            }
//            self.composedBy = composedBy
//            self.name = name
//            self.tempo = tempo
//            self.timeSignature = TimeSignature(json: json["timeSig"])
//            for i in tracks.enumerated() {
//                self.parsedTracks[i.offset].restoreChannelSettings(json: JSON(i.element))
//            }
//        } catch {
//            print(error.localizedDescription)
//        }
//    }
    
    
    
    func loadData(json: JSON) {
        self.jsonFile = json
        guard let composedBy = json["composedBy"].string, let name = json["title"].string, let tempo = json["tempo"].int, let key = json["key"].int else {
            return
        }
        self.key = key
        self.composedBy = composedBy
        self.name = name
        self.tempo = tempo
        self.timeSignature = TimeSignature(json: json["timeSig"])
        presetLoaded = true
    }
    
    func loadPreset() {
        if presetLoaded {
            for i in 0 ..< parsedTracks.count {
                self.parsedTracks[i].restoreChannelSettingsFromServer(json: self.jsonFile["tracks"][i])
            }
        }
    }

//    func loadPreset() {
//        if !presetLoaded {
//            let (instPreset, fxPreset) = STFileManager.shared.getPresetPath()
//            guard let instData = instPreset, let fxData = fxPreset else {return}
//            for i in instData {
//                let url = URL(fileURLWithPath: i)
//                let trackIndex = Int(url.fileName().components(separatedBy: "_").last!)!
//                do {
//                    self.parsedTracks[trackIndex].instrument?.reset()
//                    try self.parsedTracks[trackIndex].instrument?.loadPreset(at: url)
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }
//            for i in fxData {
//                let url = URL(fileURLWithPath: i)
//                let fileNameComponents = url.fileName().components(separatedBy: "_")
//                let trackIndex = Int(fileNameComponents[1])!
//                let effectIndex = Int(fileNameComponents[2])!
//                do {
//                    self.parsedTracks[trackIndex].effects[effectIndex].reset()
//                    try self.parsedTracks[trackIndex].effects[effectIndex].loadPreset(at: url)
//                } catch {
//                    print(error.localizedDescription)
//                }
//            }
//            presetLoaded = true
//        }
//    }
    
    func uploadToServer(billboard: String, completion: @escaping (String)->Void) {
        STFileManager.shared.uploadCurrentBlock(block: self, billboard: billboard) { (package, err, code) in
            if let pack = package ?? nil {
                completion("Musicblock uploaded!")
                self.url = pack["url"] as! String!
            }
        }
    }
    
    func getBlockLength() -> MusicTimeStamp {
        
        
        let endTimes = self.parsedTracks.map { (track) -> MusicTimeStamp in
            guard !track.notes.isEmpty else {
                return 0
            }
            return track.notes.last!.timeStamp + track.notes.last!.duration
        }
        return endTimes.max()!
    }
    
    func getJson() -> JSON {
        return self.asJSON
    }
}
