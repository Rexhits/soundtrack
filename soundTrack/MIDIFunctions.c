//
//  MIDIFuncations.c
//  soundTrack
//
//  Created by WangRex on 7/19/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

#include "MIDIFunctions.h"

// Method to add time signature event
OSStatus createTimeSignatureEvent(const UInt8 numerator, const UInt8 denominator, const MusicTrack track, const MusicTimeStamp startAt) {
    MIDIMetaEvent timeSignatureEvent;
    // Event type, 58 for time signature event
    timeSignatureEvent.metaEventType = 0x58;
    // Length of the message, 4 bytes for time signature event
    timeSignatureEvent.dataLength = 4;
    // The numerator of the time signature
    timeSignatureEvent.data[0] = numerator;
    // The denominator of the time signature
    timeSignatureEvent.data[1] = denominator;
    // Number of MIDI clocks between metronome clicks, ♩ = 24(0x18) ticks
    timeSignatureEvent.data[2] = 0x18;
    // The number of notated 32nd-notes in a MIDI quarter-note (24 MIDI Clocks), no idea what it is, usually set to 8
    timeSignatureEvent.data[3] = 0x08;
    return MusicTrackNewMetaEvent(track, startAt, &timeSignatureEvent);;
}


//OSStatus addNoteSequence(const MusicTrack track, const UInt8 toChannel, const MusicTimeStamp startAt, const UInt8 notes[], const UInt8 velocity[], const Float32 duration[]) {
//    const int length = sizeof(&notes) / sizeof(UInt8);
//    MusicTimeStamp currentTime = startAt;
//    const UInt8 statusCode = 0x96;
//    
//    OSStatus status = noErr;
//    for (int i=0; i < length-1; i++) {
//        MusicTimeStamp endAt = currentTime + duration[i];
//        MIDIChannelMessage noteOn;
//        noteOn.status = statusCode;
//        noteOn.reserved = 0;
//        noteOn.data1 = notes[i];
//        noteOn.data2 = velocity[i];
//        status = MusicTrackNewMIDIChannelEvent(track, currentTime, &noteOn);
//        noteOn.data2 = 0;
//        status = MusicTrackNewMIDIChannelEvent(track, endAt, &noteOn);
//        currentTime = endAt;
//        printf("%i", i);
//    }
//    return status;
//}
