//
//  MIDIFuncations.h
//  soundTrack
//
//  Created by WangRex on 7/19/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

#ifndef MIDIFunctions_h
#define MIDIFunctions_h

#include <stdio.h>
#include <AudioToolbox/AudioToolbox.h>

OSStatus createTimeSignatureEvent(const UInt8 numerator, const UInt8 denominator, const MusicTrack track, const MusicTimeStamp startAt);

//OSStatus addNoteSequence(const MusicTrack track, const UInt8 toChannel, const MusicTimeStamp startAt, const UInt8 notes[], const UInt8 velocity[], const Float32 duration[]);
#endif /* MIDIFunctions_h */
