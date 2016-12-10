//
//  PlaybackEngine.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AVFoundation

class PlaybackEngine: NSObject {
    static let shared = PlaybackEngine()
    private let engine = AVAudioEngine()
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
    

    
    
    private var sequencer: AVAudioSequencer!
    private var data: Data?
    private var isPlaying = false
    private var mainMixerNode: AVAudioMixerNode!
    
    public var tracks = [track]()
    public var selectedTrack: track!
    
    public enum trackType: Int {
        case instrument = 0, audio
    }
    
    class track {
        var name: String!
        var type = PlaybackEngine.trackType.instrument
        var instrument: AVAudioUnitMIDIInstrument? {
            willSet {
                name = instrument?.auAudioUnit.audioUnitName
            }
            didSet {
                name = instrument?.auAudioUnit.audioUnitName
            }
        }
        var signalChian = [AVAudioUnit]()
        var trackRef: AVMusicTrack!
        var selectedUnit: AUAudioUnit?
        var selectedUnitDescription: AudioComponentDescription?
        var selectedUnitPreset = [AUAudioUnitPreset]()
        var effects: [AVAudioUnitEffect]?
        let mixer = AVAudioMixerNode()
        init(trackType: PlaybackEngine.trackType) {
            type = trackType
            if trackType == .instrument {
                instrument = AVAudioUnitSampler()
                if name == nil {
                    name = instrument?.auAudioUnit.audioUnitName
                }
            } else {
                instrument = nil
            }
        }
    }
    
    
    override init() {
        super.init()
        mainMixerNode = engine.mainMixerNode
        let defaultTrack = track(trackType: .instrument)
        selectedTrack = defaultTrack
        // attach track's mixer
        engine.attach(defaultTrack.mixer)
        // connect track's mixer to main mixer
        engine.connect(defaultTrack.mixer, to: engine.mainMixerNode, format: audioFormat)
        self.tracks.append(defaultTrack)
        self.updateEngine()
        #if os(iOS)
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            }
            catch {
                fatalError("Can't set Audio Session category.")
            }
        #endif
        
    }
    
    
    private func setSessionActive(_ active: Bool) {
        #if os(iOS)
            do {
                try AVAudioSession.sharedInstance().setActive(active)
            }
            catch {
                fatalError("Could not set Audio Session active \(active). error: \(error).")
            }
        #endif
    }
    
    func addMusicBlock (musicBlock: MusicBlock) {
        if isPlaying == true {
            stopSequence()
        }
        sequencer = nil
        sequencer = AVAudioSequencer(audioEngine: engine)
        selectedTrack = nil
        tracks.removeAll()
        self.data = musicBlock.getSequenceData()
        if let data = self.data {
            do {
                try sequencer.load(from: data, options: .init(rawValue: 0))
                print("\(sequencer.tracks) tracks loaded, tempoTrack: \(sequencer.tempoTrack)")
            } catch {
                print("Failed load midiData! \(error)")
            }
            
            for i in sequencer.tracks {
                if i.lengthInBeats > 0 {
                    let newTrack = track(trackType: .instrument)
                    i.destinationAudioUnit = newTrack.instrument!
                    newTrack.trackRef = i
                    tracks.append(newTrack)
                    selectedTrack = newTrack
                }
            }
            updateEngineForAllTracks()
            sequencer.prepareToPlay()
        }
        if !self.engine.isRunning {
            startEngine()
        }
        playSequence()
    }
    
    func addNode(type: trackType, _ cd: AudioComponentDescription?, completionHandler: @escaping ((Void) -> Void)) {
        func done() {
            if type == .instrument {
                if sequencer != nil && isPlaying {
                    try! sequencer.start()
                }
            }
            self.updateEngine()
            completionHandler()
        }
        self.engine.connect(self.engine.mainMixerNode, to: self.engine.outputNode, format: audioFormat)
        if isPlaying {
            sequencer.stop()
        }
        
        
        if let componentDescription = cd {
            if componentDescription != selectedTrack.selectedUnitDescription {
                AVAudioUnit.instantiate(with: componentDescription, options: []) { avAudioUnit, error in
                    guard let avAudioUnit = avAudioUnit else { return }
                    if type == .instrument {
                        self.engine.disconnectNodeInput(self.selectedTrack.mixer)
                        self.engine.detach(self.selectedTrack.instrument!)
                        self.selectedTrack.instrument = avAudioUnit as? AVAudioUnitMIDIInstrument
                    } else {
                        // code for effect node
                    }
                    self.selectedTrack.selectedUnit = avAudioUnit.auAudioUnit
                    self.selectedTrack.selectedUnitPreset = avAudioUnit.auAudioUnit.factoryPresets ?? []
                    self.selectedTrack.selectedUnitDescription = cd
                    done()
                }
            } else {
                completionHandler()
            }
        } else {
            done()
        }
    }
    
    func updateEngine() {
        if let i = selectedTrack {
            // attach track's instrument
            engine.attach(i.instrument!)
            if i.type == .instrument {
                // is instrument Track
                if let seq = sequencer {
                    seq.stop()
                }
                engine.disconnectNodeInput(i.mixer)
                if let track = i.trackRef {
                    track.destinationAudioUnit = i.instrument!
                }
                if let effectNodes = i.effects {
                    // has effects
                    engine.connect(i.instrument!, to: effectNodes[0], format: audioFormat)
                    for index in 0 ..< effectNodes.count {
                        engine.attach(effectNodes[index])
                        if index < effectNodes.count - 1 {
                            // connect effects
                            engine.connect(effectNodes[index], to: effectNodes[index + 1], format: audioFormat)
                        } else {
                            // Last one to mixer
                            engine.connect(effectNodes[index], to: i.mixer, format: audioFormat)
                        }
                    }
                } else {
                    // doesn't have effect
                    engine.connect(i.instrument!, to: i.mixer, format: audioFormat)
                }
            } else {
                // is AudioTrack
            }
        }
        if let seq = sequencer {
            try! seq.start()
        }
    }
    
    func updateEngineForAllTracks() {
        for i in tracks {
            engine.attach(i.instrument!)
            engine.attach(i.mixer)
            
            if i.type == .instrument {
                // is instrument Track
                if let effectNodes = i.effects {
                    // has effects
                    engine.connect(i.instrument!, to: effectNodes[0], format: audioFormat)
                    for index in 0 ..< effectNodes.count {
                        engine.attach(effectNodes[index])
                        if index < effectNodes.count - 1 {
                            // connect effects
                            engine.connect(effectNodes[index], to: effectNodes[index + 1], format: audioFormat)
                        } else {
                            // Last one to mixer
                            engine.connect(effectNodes[index], to: i.mixer, format: audioFormat)
                        }
                    }
                } else {
                    // doesn't have effect
                    engine.connect(i.instrument!, to: i.mixer, format: audioFormat)
                }
            } else {
                // is AudioTrack
            }
            engine.connect(i.mixer, to: engine.mainMixerNode, format: audioFormat)
        }
    }
    
    private func startEngine() {
        do {
            try engine.start()
        } catch {
            print("ERROR STARTING ENGINE! \(error)")
        }
    }
    
    public func playSequence() {
        try! self.sequencer.start()
        isPlaying = true
        
    }
    public func stopSequence() {
        self.sequencer.stop()
        isPlaying = false
    }
    
    func getEngine() -> AVAudioEngine {
        return self.engine
    }
    
}
