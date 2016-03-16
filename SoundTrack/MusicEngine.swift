//
//  MusicEngine.swift
//  SoundTrack
//
//  Created by WangRex on 3/15/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioKit

class MusicEngine: NSObject {
    static let sharedInstance = MusicEngine()
    
    
    var instMixer: AKMixer?
    
    var sequencer: AKSequencer?
    
    let piano = AKSampler()
    let guitar = AKSampler()
    let bass = AKSampler()
    let drum = AKSampler()
    let strings = AKSampler()
    let horns = AKSampler()
    let pad = AKSampler()
    
    var reverb: AKReverb?
    var delay: AKDelay?
    var compressor: AKCompressor?
    
    var pianoPan: AKPanner?
    var guitarPan: AKPanner?
    var bassPan: AKPanner?
    var drumPan: AKPanner?
    var stringsPan: AKPanner?
    var hornsPan: AKPanner?
    var padPan: AKPanner?
    
    var pianoVol: AKBooster?
    var guitarVol: AKBooster?
    var bassVol: AKBooster?
    var drumVol: AKBooster?
    var stringsVol: AKBooster?
    var hornsVol: AKBooster?
    var padVol: AKBooster?
    
    var timer: NSTimer?
    
    override init() {
        super.init()
        pianoPan = AKPanner(piano)
        guitarPan = AKPanner(guitar)
        bassPan = AKPanner(bass)
        drumPan = AKPanner(drum)
        stringsPan = AKPanner(strings)
        hornsPan = AKPanner(horns)
        padPan = AKPanner(pad)
        
        pianoVol = AKBooster(pianoPan!)
        guitarVol = AKBooster(guitarPan!)
        bassVol = AKBooster(bassPan!)
        drumVol = AKBooster(drumPan!)
        stringsVol = AKBooster(stringsPan!)
        hornsVol = AKBooster(hornsPan!)
        padVol = AKBooster(padPan!)
        
        instMixer = AKMixer(pianoVol!, guitarVol!, bassVol!, drumVol!, stringsVol!, hornsVol!, padVol!)
        
        delay = AKDelay(instMixer!)
        reverb = AKReverb(delay!)
        reverb!.loadFactoryPreset(AVAudioUnitReverbPreset.LargeHall)
        delay!.time = 0.2
        delay!.feedback = 0.1
        delay!.dryWetMix = 0
        reverb!.dryWetMix = 0
        compressor = AKCompressor(reverb!, threshold: -20, headRoom: 2, attackTime: 0.01, releaseTime: 0.05, masterGain: 20)
        compressor!.dryWetMix = 30
        AudioKit.output = compressor
        AudioKit.start()
        
        // Let audio play in background
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryMultiRoute)
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
                piano.loadEXS24(filename[i])
                
            case "guiar":
                guitar.loadSoundfont(filename[i])
                
            case "bass":
                bass.loadEXS24(filename[i])
                
            case "drum":
                drum.loadEXS24(filename[i])
                
            case "strings":
                strings.loadEXS24(filename[i])
                
            case "horns" :
                horns.loadEXS24(filename[i])
                
            case "pad" :
                pad.loadEXS24(filename[i])
                
            default:
                break
                
            }
        }
    }
    
    
    func loadMidiFile (filename: String, insts: [String]) {
        // fuction for load midi file
        
        
        sequencer = AKSequencer(filename: filename, engine: AudioKit.engine)
        sequencer!.loopOn()

            
        let currentTrack = sequencer!.avTracks
            
        for var i = 0; i < insts.count; i++ {
                
            switch insts[i] {
            case "piano" :
                currentTrack[i+1].destinationAudioUnit = self.piano.samplerUnit
                    
            case "guitar" :
                currentTrack[i+1].destinationAudioUnit = self.guitar.samplerUnit
                    
            case "bass" :
                currentTrack[i+1].destinationAudioUnit = self.bass.samplerUnit
                    
            case "drum" :
                currentTrack[i+1].destinationAudioUnit = self.drum.samplerUnit
                    
            case "strings" :
                currentTrack[i+1].destinationAudioUnit = self.strings.samplerUnit
                    
            case "horns" :
                currentTrack[i+1].destinationAudioUnit = self.horns.samplerUnit
                    
            case "pad" :
                currentTrack[i+1].destinationAudioUnit = self.pad.samplerUnit
                
            default :
                break
            }
        }
        
    }
    
    func play() {
        
        pianoVol!.gain = 1
        bassVol!.gain = 0.5
        drumVol!.gain = 2
        sequencer!.play()

    }
    
    func stop() {
        sequencer!.stop()
        sequencer!.rewind()
        sequencer!.setRate(0.5)
        if (self.timer != nil) {
            self.timer!.invalidate()
            self.timer = nil
        }
        pianoVol!.gain = 0
        bassVol!.gain = 0
        drumVol!.gain = 0
        
    }
    
    func intelligentPlay () {
        
        
        sequencer!.play()
        self.timer = NSTimer.scheduledTimerWithTimeInterval(0.01, target: self, selector: "intelligent", userInfo: nil, repeats: true)
    }
    
    func intelligent() {
        let currentBeat = sequencer!.avSeq.currentPositionInBeats
        
        if (currentBeat < 15.5) {
            pianoVol!.gain = 1
            bassVol!.gain = 0
            drumVol!.gain = 0
        } else if (currentBeat > 15.9 && currentBeat < 31.5) {
            pianoVol!.gain = 1
            bassVol!.gain = 0.5
            drumVol!.gain = 0
        } else if (currentBeat > 31.9 && currentBeat < 62.5) {
            print(">32")
            pianoVol!.gain = 1
            bassVol!.gain = 0.5
            drumVol!.gain = 2
        } else if (currentBeat > 87.9 && currentBeat < 91.5) {
            pianoVol!.gain = 1
            bassVol!.gain = 0.5
            drumVol!.gain = 0
            
        } else if (currentBeat > 91.95) {
            pianoVol!.gain = 1.4
            bassVol!.gain = 0.8
            drumVol!.gain = 2
        }
    }

}