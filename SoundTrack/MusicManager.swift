//
//  music.swift
//  SoundTrack
//
//  Created by WangRex on 3/10/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class MusicManager: NSObject {
    static let sharedInstance = MusicManager()
    
    // AVAudioEngine
    let engine = AVAudioEngine()
    
    // Sequencer to be attached to audio engine
    var sequencer: AVAudioSequencer?
    
    // Instruments
    let piano = AVAudioUnitSampler()
    let guitar = AVAudioUnitSampler()
    let bass = AVAudioUnitSampler()
    let drum = AVAudioUnitSampler()
    let strings = AVAudioUnitSampler()
    let horns = AVAudioUnitSampler()
    let pad = AVAudioUnitSampler()
    
    // Effects
    let reverb = AVAudioUnitReverb()
    let delay = AVAudioUnitDelay()
    //Mixer
    let mixer = AVAudioMixerNode()
    
    // Connection format
    let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.PCMFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)
    
    var timer: NSTimer?
    // Initiallization
    override init() {
        super.init()
        engine.reset()
        
        //some preset
        piano.volume = 0
        bass.volume = 0
        drum.volume = 0
        reverb.loadFactoryPreset(AVAudioUnitReverbPreset.LargeHall)
        delay.delayTime = 0.2
        delay.feedback = 50
        delay.wetDryMix = 0
        reverb.wetDryMix = 0
        
        // Attach all nodes to engine
        engine.attachNode(piano)
        engine.attachNode(guitar)
        engine.attachNode(bass)
        engine.attachNode(drum)
        engine.attachNode(strings)
        engine.attachNode(horns)
        engine.attachNode(pad)
        
        engine.attachNode(reverb)
        engine.attachNode(delay)
        engine.attachNode(mixer)
        
        // Make all the connections
        engine.connect(piano, to: mixer, format: format)
        engine.connect(guitar, to: mixer, format: format)
        engine.connect(bass, to: mixer, format: format)
        engine.connect(drum, to: mixer, format: format)
        engine.connect(strings, to: mixer, format: format)
        engine.connect(horns, to: mixer, format: format)
        engine.connect(pad, to: mixer, format: format)
    
        engine.connect(mixer, to: delay, format: format)
        engine.connect(delay, to: reverb, format: format)
        
        engine.connect(reverb, to: engine.mainMixerNode, format: format)
        


        
        sequencer = AVAudioSequencer(audioEngine: engine)
        
        do {
            try engine.start()
        } catch let error as NSError {
            print(error)
        }
        
        
        // Let audio play in background
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
    }

    
    func loadPatch(inst: [String], filename: [String]) {
        // function for loading instruments
        print(inst.count)
        for var i = 0; i < inst.count; i++ {
            print("loading")
            switch inst[i] {
            case "piano":
                
                guard let soundfile = NSBundle.mainBundle().URLForResource(filename[i], withExtension: "exs")
                    else {
                        print("could not read piano")
                        return
                }

                do {
                    try piano.loadInstrumentAtURL(soundfile)
                    
                } catch let error as NSError {
                    print("\(error.localizedDescription)")
                    return
                }

            case "guiar":
                guard let soundfile = NSBundle.mainBundle().URLForResource(filename[i], withExtension: "exs")
                    else {
                        print("could not read guitar")
                        return
                }
                
                do {
                    try guitar.loadInstrumentAtURL(soundfile)
                    
                } catch let error as NSError {
                    print("\(error.localizedDescription)")
                    return
                }

            case "bass":
                guard let soundfile = NSBundle.mainBundle().URLForResource(filename[i], withExtension: "exs")
                    else {
                        print("could not read bass")
                        return
                }
                
                do {
                    try bass.loadInstrumentAtURL(soundfile)
                    
                } catch let error as NSError {
                    print("\(error.localizedDescription)")
                    return
                }
                
            case "drum":
                guard let soundfile = NSBundle.mainBundle().URLForResource(filename[i], withExtension: "exs")
                    else {
                        print("could not read drum")
                        return
                }
                
                do {
                    try drum.loadInstrumentAtURL(soundfile)
                    
                } catch let error as NSError {
                    print("\(error.localizedDescription)")
                    return
                }
                
            case "strings":
                guard let soundfile = NSBundle.mainBundle().URLForResource(filename[i], withExtension: "exs")
                    else {
                        print("could not read strings")
                        return
                }
                
                do {
                    try strings.loadInstrumentAtURL(soundfile)
                    
                } catch let error as NSError {
                    print("\(error.localizedDescription)")
                    return
                }
                
            case "horns" :
                guard let soundfile = NSBundle.mainBundle().URLForResource(filename[i], withExtension: "exs")
                    else {
                        print("could not read horns")
                        return
                }
                
                do {
                    try horns.loadInstrumentAtURL(soundfile)
                    
                } catch let error as NSError {
                    print("\(error.localizedDescription)")
                    return
                }
            case "pad" :
                guard let soundfile = NSBundle.mainBundle().URLForResource(filename[i], withExtension: "exs")
                    else {
                        print("could not read pad")
                        return
                }
                
                do {
                    try pad.loadInstrumentAtURL(soundfile)
                    
                } catch let error as NSError {
                    print("\(error.localizedDescription)")
                    return
                }
                
            default:
                break
                
            }
        }
    }
    
    func loadMidiFile (filename: String, insts: [String]) {
        // fuction for load midi file
        
        guard let midiFile = NSBundle.mainBundle().URLForResource(filename, withExtension: "mid")
            else {
                print("Midi file not found")
                return
        }
        try! sequencer!.loadFromURL(midiFile, options: .SMF_PreserveTracks)
        
        for track:AVMusicTrack in sequencer!.tracks {
            
            track.loopingEnabled = true
            track.loopRange = AVBeatRange(start: 0, length: 32)
            
            let currentTrack = sequencer!.tracks
            for var i = 0; i < insts.count; i++ {
                
                switch insts[i] {
                case "piano" :
                    currentTrack[i+1].destinationAudioUnit = self.piano
                    
                case "guitar" :
                currentTrack[i+1].destinationAudioUnit = self.guitar
                    
                case "bass" :
                    currentTrack[i+1].destinationAudioUnit = self.bass
                    
                case "drum" :
                    currentTrack[i+1].destinationAudioUnit = self.drum
                    
                case "strings" :
                    currentTrack[i+1].destinationAudioUnit = self.strings
                    
                case "horns" :
                    currentTrack[i+1].destinationAudioUnit = self.horns
                    
                case "pad" :
                    currentTrack[i+1].destinationAudioUnit = self.pad
                    
                default :
                    break
                }
            }
            
        }
        sequencer!.prepareToPlay()
    }

    func play() {
        
        piano.volume = 1
        bass.volume = 0.5
        drum.volume = 2
        
        do {
        try sequencer!.start()
        
        } catch let error as NSError {
            print("\(error.localizedDescription)")
            return
        }
    }
    
    func stop() {
        sequencer!.stop()
        sequencer!.currentPositionInBeats = 0
        self.timer = nil
    }
    

    
    func intelligentPlay () {
        sequencer!.rate = 1
        piano.volume = 0
        bass.volume = 0
        drum.volume = 0
        do {
            try sequencer!.start()
            
        } catch let error as NSError {
            print("\(error.localizedDescription)")
            return
        }

        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "intelligent", userInfo: nil, repeats: true)
    }
    
    func intelligent() {
        let currentBeat = sequencer!.currentPositionInBeats
        let track = sequencer!.tracks
        if (currentBeat < 15.5) {
            sequencer!.rate = 1
            piano.volume = 1
            bass.volume = 0
            drum.volume = 0
        } else if (currentBeat > 15.9 && currentBeat < 31.5) {
            piano.volume = 1
            bass.volume = 0.5
            drum.volume = 0
        } else if (currentBeat > 31.9 && currentBeat < 62.5) {
            print(">32")
            piano.volume = 1
            bass.volume = 0.5
            drum.volume = 2
        } else if (currentBeat > 87.9 && currentBeat < 91.5) {
            drum.volume = 1
            bass.volume = 0.5
            piano.volume = 0
            
        } else if (currentBeat > 91.95) {
            piano.volume = 1.4
            bass.volume = 0.8
            drum.volume = 2
        }
    }
}