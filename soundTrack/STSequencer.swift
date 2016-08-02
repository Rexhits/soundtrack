//
//  MIDIEngine.swift
//  soundTrack
//
//  Created by WangRex on 7/18/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox


// Enumeration of channel events



// Data structure of a note sequence
struct NoteEvents {
    // Note set
    let note: [UInt8]
    // Volocity set
    let velocity: [UInt8]
    // Set of duration of each note
    let duration: [Float32]
}

// Data structure of a channel event
struct ChannelEvent {
    enum EventStatus: UInt8 {
        case Aftertouch = 0xA0
        case Controller = 0xB0
        case Pitchbend = 0xF0
    }
    let status: EventStatus
    let controllerNumber: UInt8
    let value: UInt8
    let reserved: UInt8?
}


// A music sequence implemented based on MusicSequence in AudioToolbox
class STSequencer: NSObject, CsoundObjListener {
    // Create a singleton
    static let sharedInstance = STSequencer()
    // The sequencer
    private var sequencer: MusicSequence?
    // MusicTracks in the sequencer, without the tempo track, start with 0
    var tracks = [MusicTrack]()
    // TempoTrack of the sequencer, not included in "tracks"
    private var tempoTrack: MusicTrack?
    
    private var midiClient = MIDIClientRef()
    private var virtualSourceEndpointRef = MIDIEndpointRef()
    private var notifyBlock: MIDINotifyBlock?
    private var readBlock: MIDIReadBlock!

    private var musicPlayer: MusicPlayer?
    
    let csound = CsoundObj()
    
    // Initiallization
    override init() {
        super.init()
        csound.add(self)
//        notifyBlock = self.myNotifyCallback
        readBlock = self.myReadBlock
        addTempoEvent(bpm: 120, startAt: 0)
        addTimeSignatureEvent(numerator: 4, denominator: 4, startAt: 0)
        // Create a MusicSequence
        var status = NewMusicSequence(&sequencer)
        if status != OSStatus(noErr) {
            print("\(#line) bad status \(status) creating sequence")
        } else {
            print("sequence created")
        }
        status = NewMusicPlayer(&musicPlayer)
        if status != OSStatus(noErr) {
            print("\(#line) bad status \(status) creating music player")
        } else {
            print("music player created")
        }
        MusicPlayerSetSequence(musicPlayer!, sequencer)
        // Get the tempo track
        self.getTempoTrack()
        // Add a new track
        self.newTrack()
        
        
    }
    // Method to add a new track
    func newTrack() {
        // Creating a new track
        var newTrack: MusicTrack?
        // Add to the sequencer
        let status = MusicSequenceNewTrack(sequencer!, &newTrack)
        if status != OSStatus(noErr) {
            print("error creating track \(status)")
        } else {
            // Store the new track to "tracks" array
            tracks.append(newTrack!)
            print("new track created at track \(tracks.count)")
        }
        self.outputToCsound()
    }
    // Method to get the tempo track
    func getTempoTrack() {
        // Get the tempo track and store it to "tempoTrack"
        let status = MusicSequenceGetTempoTrack(sequencer!, &tempoTrack)
        if status != OSStatus(noErr) {
            print("error getting tempo track \(status)")
        } else {
            print("got tempo track")
        }
    }
    
    // Method to add tempo event
    func addTempoEvent(bpm: Float64, startAt: MusicTimeStamp) {
        if tempoTrack != nil {
            if startAt == 0 {
                // Clear the tempo track if the event start at the beginning, in case there're multiple tempo event there
                MusicTrackClear(tempoTrack!, 0, 1)
            }
            // Add event to tempo track
            let status = MusicTrackNewExtendedTempoEvent(tempoTrack!, startAt, bpm)
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
    func addTimeSignatureEvent(numerator: UInt8, denominator:UInt8, startAt: MusicTimeStamp) {
        // Convert raw denominator into required value (a negative power of 2: 2 = quarter note, 3 = eighth, 4 = 16 etc)
        let denominatorOut = UInt8(log2f(Float(denominator)))
        if tempoTrack != nil {
            // Call our C function to add the event, directly using swift doesn't work (can't edit the denominator)
            let status = createTimeSignatureEvent(numerator, denominatorOut, tempoTrack, startAt)
            if status != OSStatus(noErr) {
                print("error adding time signature \(status)")
            } else {
                print("new timesignature added: \(numerator) / \(denominator), at timestamp:\(startAt)")
            }
        } else {
            print("tempo track not found")
        }
        
    }
    
    // Method to add note set
    func addNoteEvents(events: NoteEvents, toTrack: Int, toChannel: UInt8, startAt: MusicTimeStamp) -> MusicTimeStamp {
         // Add every note event to the track
        var currentTimeStamp = startAt + 1
        for i in 0..<events.note.count {
            var message = MIDINoteMessage(channel: toChannel, note: events.note[i], velocity: events.velocity[i], releaseVelocity: 0, duration: events.duration[i])
            // print(message)
            MusicTrackNewMIDINoteEvent(tracks[toTrack], currentTimeStamp, &message)
            currentTimeStamp += MusicTimeStamp(events.duration[i])
        }

        return currentTimeStamp
    }
    
    // Method to add channel event such as controller event
    func addChannelEvent(event: ChannelEvent, toTrack: Int, toChannel: UInt8, at: MusicTimeStamp) {
        var reserved = UInt8(0);
        if event.reserved != nil {
            reserved = event.reserved!
        }
        var status: UInt8 = event.status.rawValue
        status += toChannel
        var message = MIDIChannelMessage(status: status, data1: event.controllerNumber, data2: event.value, reserved: reserved)
        MusicTrackNewMIDIChannelEvent(tracks[toTrack], at + 1, &message)
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
    
    func outputToCsound() {
        
        var status = MIDIClientCreateWithBlock("myClient", &midiClient, notifyBlock)
        if status != OSStatus(noErr) {
            print("error creating midi client \(status)")
        } else {
            print("midi client created")
        }
        status = MIDIDestinationCreateWithBlock(midiClient, "VirtualDest", &virtualSourceEndpointRef, readBlock!)
        if status != OSStatus(noErr) {
            print("error creating midi destination \(status)")
        } else {
            print("midi destination created")
        }
        
        status = MusicSequenceSetMIDIEndpoint(sequencer!, virtualSourceEndpointRef)
        if status != OSStatus(noErr) {
            print("error setting midi endpoint \(status)")
        } else {
            print("midi endpoint set")
        }
        
        status = MIDISourceCreate(midiClient,
                                  "virtualSource",
                                  &virtualSourceEndpointRef)
        if status != OSStatus(noErr) {
            print("error creating midi source \(status)")
        } else {
            print("midi source created")
        }

    }
    
    private func myNotifyCallback(message:UnsafePointer<MIDINotification>) -> Void {
        let notification = message.pointee
        print("MIDI Notify, messageId= \(notification.messageID)")
        
        switch (notification.messageID) {
        case MIDINotificationMessageID.msgSetupChanged:
            NSLog("MIDI setup changed")
            break
            
        case MIDINotificationMessageID.msgObjectAdded:
            NSLog("added")
            let mp = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(message)
            let m:MIDIObjectAddRemoveNotification = mp.pointee
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("child \(m.child)")
            print("child type \(m.childType)")
            print("parent \(m.parent)")
            print("parentType \(m.parentType)")
            
            break
            
        case MIDINotificationMessageID.msgObjectRemoved:
            NSLog("kMIDIMsgObjectRemoved")
            let mp = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(message)
            let m:MIDIObjectAddRemoveNotification = mp.pointee
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("child \(m.child)")
            print("child type \(m.childType)")
            print("parent \(m.parent)")
            print("parentType \(m.parentType)")
            
            break
            
        case MIDINotificationMessageID.msgPropertyChanged :
            NSLog("kMIDIMsgPropertyChanged")
            let mp = UnsafeMutablePointer<MIDIObjectPropertyChangeNotification>(message)
            let m:MIDIObjectPropertyChangeNotification = mp.pointee
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("property name \(m.propertyName)")
            print("object type \(m.objectType)")
            print("object \(m.object)")
            
            break
            
        case MIDINotificationMessageID.msgThruConnectionsChanged :
            NSLog("MIDI thru connections changed.")
            break
            
        case MIDINotificationMessageID.msgSerialPortOwnerChanged :
            NSLog("MIDI serial port owner changed.")
            break
            
        case MIDINotificationMessageID.msgIOError :
            NSLog("MIDI I/O error.")
            break
            
        }

    }

    
    private func myReadBlock(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutablePointer<Void>?) -> Void {
//        print("sending packets to source \(packetList)")
        MIDIReceived(virtualSourceEndpointRef, packetList)
//        dumpPacketList(packetlist: packetList.pointee)
    }
    
    private func dumpPacketList(packetlist:MIDIPacketList) {
        let packet = packetlist.packet
        var ap = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        ap.initialize(to: packet)
        for _ in 0 ..< packetlist.numPackets {
            let p = ap.pointee
            dump(p)
            ap = MIDIPacketNext(ap)
        }
    }
    
    func start() {
        loadCSD()
        MusicPlayerPreroll(musicPlayer!)
        MusicPlayerStart(musicPlayer!)
        
    }
    
    func stop() {
        MusicPlayerStop(musicPlayer!)
        MusicPlayerPreroll(musicPlayer!)
        self.csound.stop()
    }
    
    // for test!!!
    func loadCSD() {
        
        let path = Bundle.main.path(forResource: "midiTest", ofType: "csd")
        
        csound.midiInEnabled = true
        csound.play(path)
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
    
    func loopTrack(musicTrack:MusicTrack)   {
        
        let trackLength = getTrackLength(musicTrack: musicTrack)
        print("track length is \(trackLength)")
        setTrackLoopDuration(musicTrack: musicTrack, duration: trackLength - 1)
        
        
    }
}









