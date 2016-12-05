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
    
    init(url: NSURL) {
        super.init()
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
        if trackCount <= 1 {
            // only one track
            var track: MusicTrack?
            MusicSequenceGetIndTrack(sequencer!, 0, &track)
            tracks.append(track!)
        }
    }
    
    
    
    func parse() {
        if tempoTrack != nil {
            self.parsedTempoTrack = getInfo(track: tempoTrack!)
        }
        for i in tracks {
            self.parsedTracks.append(getInfo(track: i))
        }
        for i in 0 ..< parsedTracks.count {
            parsedTracks[i].musicTrack = tracks[i]
        }
    }
    
    private func getInfo(track: MusicTrack) -> Track{
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
                let noteEvent = NoteEvent(timeStamp: newInfo.timeStamp, channel: Int(mess.channel), note: Int(mess.note), velocity: Int(mess.velocity), duration: mess.duration)
                newTrack.addNote(note: noteEvent)
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
        return newTrack
    }
}


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
}


class Player: NSObject {
    var sequencer: MusicSequence?
    var processGraph: AUGraph?
    var tracks = [MusicTrack]()
    var ioNode = AUNode()
    var ioUnit: AudioUnit?
    var outIsInitialized:DarwinBoolean = false
    var isRunning:DarwinBoolean = false
    var isPlaying:DarwinBoolean = false
    private var musicPlayer: MusicPlayer?
    override init() {
        
    }
    init(sequence: MusicBlock) {
        super.init()
        self.sequencer = sequence.getSequencer()
        self.tracks = sequence.tracks
        processGraphSetUp()
        MusicSequenceSetAUGraph(self.sequencer!, self.processGraph!)
        let status = NewMusicPlayer(&musicPlayer)
        if status != OSStatus(noErr) {
            print("\(#line) bad status \(status) creating music player")
        } else {
            print("music player created")
        }
        
        for i in tracks {
            // plug Audio Unit
        }
        MusicPlayerSetSequence(musicPlayer!, self.sequencer)
        
    }
    
    func start() {
        MusicPlayerStart(musicPlayer!)
        MusicPlayerIsPlaying(self.musicPlayer!, &self.isPlaying)
    }
    
    func stop() {
        MusicPlayerStop(musicPlayer!)
        MusicPlayerIsPlaying(self.musicPlayer!, &self.isPlaying)
    }
    
    /*
     The default looping behaviour is off (track plays once)
     Looping is set by specifying the length of the loop. It loops from
     (TrackLength - loop length) to Track Length
     If numLoops is set to zero, it will loop forever.
     To turn looping off, you set this with loop length equal to zero.
     */
    private func setTrackLoopDuration(musicTrack:MusicTrack, duration:MusicTimeStamp)   {
        print("loop duration to \(duration)")
        
        //To loop forever, set numberOfLoops to 0. To explicitly turn off looping, specify a loopDuration of 0.
        var loopInfo = MusicTrackLoopInfo(loopDuration: duration, numberOfLoops: 0)
        let lisize = UInt32(0)
        let status = MusicTrackSetProperty(musicTrack, UInt32(kSequenceTrackProperty_LoopInfo), &loopInfo, lisize )
        if status != OSStatus(noErr) {
            print("Error setting loopinfo on track \(status)")
            return
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
    
    func loopTrack() {
        var length = MusicTimeStamp()
        for i in tracks {
            let trackLength = getTrackLength(musicTrack: i)
            if trackLength > length {
                length = trackLength
            }
        }
        for i in tracks {
            setTrackLoopDuration(musicTrack: i, duration: length)
        }
    }
    
    private func processGraphSetUp() {
        var status = NewAUGraph(&self.processGraph)
        if status != OSStatus(noErr) {
            print("\(#line) bad status \(status) creating AUGraph")
        } else {
            print("AUGraph created")
        }
        
        var ioUnitDescription = AudioComponentDescription(componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_RemoteIO, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
        status = AUGraphAddNode(self.processGraph!, &ioUnitDescription, &ioNode)
        status = AUGraphOpen(self.processGraph!)
        status = AUGraphNodeInfo(self.processGraph!, ioNode, nil, &ioUnit)
        
    }
    
    func addNode(auComponent: AVAudioUnitComponent, completionHandler: @escaping ((Void) -> Void)) {
        var node = AUNode()
        var audiounit: AudioUnit?
        let type = auComponent.typeName
        if type == "Music Device" && isPlaying == true {
            MusicPlayerStop(self.musicPlayer!)
        }
        var des = auComponent.audioComponentDescription
        var status = AUGraphAddNode(self.processGraph!, &des, &node)

//        status = AUGraphNodeInfo(self.processGraph!, node, nil, &audiounit)
//        status = AUGraphConnectNodeInput(self.processGraph!, node, 0, self.ioNode, 0)
        completionHandler()
    }
    
    func startGraph() {
        AUGraphIsInitialized(self.processGraph!, &outIsInitialized)
        if outIsInitialized == false {
            AUGraphInitialize(self.processGraph!)
        }
        AUGraphIsRunning(self.processGraph!, &isRunning)
        if isRunning == false {
            AUGraphStart(self.processGraph!)
        }
    }
    
    static func getAvailableAUList(type: auType) -> [AVAudioUnitComponent] {
        var componentDescription = AudioComponentDescription()
        componentDescription.componentType = type.getType()
        componentDescription.componentSubType = 0
        componentDescription.componentManufacturer = 0
        componentDescription.componentFlags = 0
        componentDescription.componentFlagsMask = 0
        return AVAudioUnitComponentManager.shared().components(matching: componentDescription)
    }
    
}


