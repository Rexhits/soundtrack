//
//  PlaybackEngine.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class PlaybackEngine: NSObject {
    static let shared = PlaybackEngine()
    private let engine = AVAudioEngine()
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
    

    public var loadedBlock: MusicBlock? {
        didSet {
            delegate?.didLoadBlock(block: loadedBlock!)
        }
    }
    public var delegate: PlaybackEngineDelegate?
    private var timer: Timer?
    private var sequencer: AVAudioSequencer!
    private var data: Data?
    public var isPlaying = false
    public var isLooping = false
    private var mainMixerNode: AVAudioMixerNode!
    public var blockLength: AVMusicTimeStamp = 0
    public var tracks = [track]()
    public var selectedTrack: track!
    
    public enum trackType: Int {
        case instrument = 0, audio
    }
    
    
    class track {
        var trackIndex: Int!
        var instrumentView: UIView?
        var name: String!
        var type = PlaybackEngine.trackType.instrument
        var instrument: AVAudioUnitMIDIInstrument? {
            willSet {
                name = instrument?.auAudioUnit.audioUnitName
            }
            didSet {
                if instrument != oldValue {
                    name = instrument?.auAudioUnit.audioUnitName
                    instrument!.auAudioUnit.requestViewController { [weak self] viewController in
                        guard let strongSelf = self else {return}
                        guard let vc = viewController, let view = vc.view else {
                            /*
                             Show placeholder text that tells the user the audio unit has
                             no view.
                             */
                            strongSelf.instrumentView = nil
                            return
                            
                        }
                        strongSelf.instrumentView = view
                    }
                }
            }
        }
        var selectedNode: AVAudioUnit?
        var selectedUnit: AUAudioUnit?
        var selectedUnitDescription: AudioComponentDescription?
        var trackColor: UIColor?
        var selectedUnitPreset = [AUAudioUnitPreset]()
        var effects = [AVAudioUnitEffect]()
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
        engine.attach(defaultTrack.instrument!)
        engine.attach(defaultTrack.mixer)
        engine.connect(defaultTrack.instrument!, to: defaultTrack.mixer, format: audioFormat)
        // connect track's mixer to main mixer
        engine.connect(defaultTrack.mixer, to: engine.mainMixerNode, format: audioFormat)
        self.tracks.append(defaultTrack)
        
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
        self.loadedBlock = musicBlock
        sequencer = nil
        sequencer = AVAudioSequencer(audioEngine: engine)
        selectedTrack = nil
        for i in tracks {
            engine.detach(i.instrument!)
            for e in i.effects {
                engine.detach(e)
            }
            engine.detach(i.mixer)
        }
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
                let newTrack = track(trackType: .instrument)
                tracks.append(newTrack)
                selectedTrack = newTrack
                i.destinationAudioUnit = newTrack.instrument!
                engine.attach(newTrack.instrument!)
                engine.attach(newTrack.mixer)
                if !newTrack.effects.isEmpty {
                    for e in 0 ..< newTrack.effects.count {
                        engine.attach(newTrack.effects[e])
                        if e < newTrack.effects.count - 1{
                            engine.connect(selectedTrack.effects[e], to: selectedTrack.effects[e+1], format: audioFormat)
                        }
                    }
                    engine.connect(newTrack.instrument!, to: newTrack.effects[0], format: audioFormat)
                    engine.connect(newTrack.effects.last!, to: newTrack.mixer, format: audioFormat)
                } else {
                    engine.connect(newTrack.instrument!, to: newTrack.mixer, format: audioFormat)
                }
                engine.connect(newTrack.mixer, to: engine.mainMixerNode, format: audioFormat)
                if i.lengthInBeats > blockLength {
                    blockLength = i.lengthInBeats
                }
            }
            sequencer.prepareToPlay()
        }
        if !self.engine.isRunning {
            startEngine()
        }
        playSequence()
    }
    
    func addNode(type: trackType, adding: Bool?, _ cd: AudioComponentDescription?, completionHandler: @escaping ((Void) -> Void)) {
        func done() {
            playSequence()
            completionHandler()
        }
        if isPlaying {
            stopSequence()
        }
        if let componentDescription = cd {
            AVAudioUnit.instantiate(with: componentDescription, options: []) { avAudioUnit, error in
                guard let avAudioUnit = avAudioUnit else { return }
                if type == .instrument {
                    if self.selectedTrack.selectedUnitDescription != componentDescription {
                        self.newInst(newNode: avAudioUnit)
                    }
                    
                } else {
                    if adding! {
                        self.addEffect(newNode: avAudioUnit)
                    } else {
                        self.removeEffect(unit: self.selectedTrack.selectedNode!)
                        self.addEffect(newNode: avAudioUnit)
                    }
                }
                self.selectedTrack.selectedNode = avAudioUnit
                self.selectedTrack.selectedUnit = avAudioUnit.auAudioUnit
                self.selectedTrack.selectedUnitPreset = avAudioUnit.auAudioUnit.factoryPresets ?? []
                self.selectedTrack.selectedUnitDescription = avAudioUnit.audioComponentDescription
                done()
            }
        } else {
            done()
        }
    }
    
    private func newInst(newNode: AVAudioUnit) {
        if let i = selectedTrack {
            engine.detach(i.instrument!)
            engine.attach(newNode)
            if !i.effects.isEmpty {
                engine.disconnectNodeInput(i.effects.first!)
                engine.connect(newNode, to: i.effects.first!, format: audioFormat)
            } else {
                engine.disconnectNodeInput(i.mixer)
                engine.connect(newNode, to: i.mixer, format: audioFormat)
            }
            i.instrument = newNode as? AVAudioUnitMIDIInstrument
            if let seq = sequencer {
                for s in seq.tracks {
                    s.destinationAudioUnit = i.instrument!
                }
            }
        }
    }

    private func addEffect(newNode: AVAudioUnit) {
        if let i = selectedTrack {
            engine.attach(newNode)
            if !i.effects.isEmpty && i.effects.count == 1{
                engine.connect(i.effects.first!, to: newNode, format: audioFormat)
                
            }
            else if i.effects.count > 1 {
                engine.connect(i.effects[i.effects.count - 1], to: newNode, format: audioFormat)
            } else {
                engine.disconnectNodeInput(i.mixer)
                engine.disconnectNodeOutput(i.instrument!)
                engine.connect(i.instrument!, to: newNode, format: audioFormat)
                
            }
            engine.connect(newNode, to: i.mixer, format: audioFormat)
            i.effects.append(newNode as! AVAudioUnitEffect)
        }
    }
    

    
    public func removeEffect(index: Int) {
        if let i = selectedTrack {
            stopSequence()
            let oldNode = i.effects[index]
            engine.disconnectNodeInput(oldNode)
            engine.disconnectNodeOutput(oldNode)
            engine.detach(oldNode)
            if i.effects.count == 1 {
                engine.disconnectNodeInput(i.mixer)
                engine.connect(i.instrument!, to: i.mixer, format: audioFormat)
            }
            else if index == 0 && i.effects.count > 1 {
                engine.connect(i.instrument!, to: i.effects[index + 1], format: audioFormat)
            }
            else if index == i.effects.count - 1{
                engine.connect(i.effects[index - 1], to: i.mixer, format: audioFormat)
            } else {
                engine.connect(i.effects[index - 1], to: i.effects[index + 1], format: audioFormat)
            }
            i.effects.remove(at: index)
            selectedTrack.selectedUnit = nil
            selectedTrack.selectedUnitDescription = nil
            selectedTrack.selectedUnitPreset = [AUAudioUnitPreset]()
            playSequence()
        }

    }
    
    public func removeEffect(unit: AVAudioUnit) {
        guard let unit = unit as? AVAudioUnitEffect else {
            return
        }
        if let index = selectedTrack.effects.index(of: unit) {
            if let i = selectedTrack {
                stopSequence()
                let oldNode = i.effects[index]
                engine.detach(oldNode)
                if i.effects.count == 1 {
//                    engine.connect(i.instrument!, to: i.mixer, format: audioFormat)
                }
                else if index == 0 && i.effects.count > 1 {
                    engine.connect(i.instrument!, to: i.effects[index + 1], format: audioFormat)
                }
                else if index == i.effects.count - 1{
                    engine.connect(i.effects[index - 1], to: i.mixer, format: audioFormat)
                } else {
                    engine.connect(i.effects[index - 1], to: i.effects[index + 1], format: audioFormat)
                }
                i.effects.remove(at: index)
                selectedTrack.selectedUnit = nil
                selectedTrack.selectedUnitDescription = nil
                selectedTrack.selectedUnitPreset = [AUAudioUnitPreset]()
            }
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
        if let sequencer = self.sequencer {
            if !isPlaying {
                sequencer.prepareToPlay()
                do {
                    try sequencer.start()
                } catch {
                    print(error)
                }
                isPlaying = true
                delegate?.didStartPlaying()
                timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(playtimeObserver), userInfo: nil, repeats: true)
            }
        }
        
    }
    public func stopSequence() {
        if let sequencer = self.sequencer {
            if isPlaying {
                sequencer.stop()
                isPlaying = false
                delegate?.didFinishPlaying()
            }
            
        }
    }
    
    public func startLoop() {
        if let sequencer = self.sequencer {
            for i in sequencer.tracks {
                i.isLoopingEnabled = true
                i.numberOfLoops = -1
                isLooping = true
                delegate?.didStartLoop()
            }
        }
    }
    public func stopLoop() {
        if let sequencer = self.sequencer {
            for i in sequencer.tracks {
                i.isLoopingEnabled = false
                isLooping = false
                delegate?.didFinishLoop()
            }
        }
    }
    
    
    func getEngine() -> AVAudioEngine {
        return self.engine
    }
    func isReadyToPlay() -> Bool {
        return self.sequencer != nil && self.data != nil
    }
    func playtimeObserver() {
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            let currentTime = self.sequencer.currentPositionInBeats
            self.delegate?.updateTime(currentTime: currentTime)
            if currentTime >= self.blockLength {
                DispatchQueue.main.sync {
                    if !self.isLooping && self.isPlaying {
                        self.timer!.invalidate()
                        self.timer = nil
                        self.stopSequence()
                        self.sequencer.currentPositionInBeats = AVMusicTimeStamp(0)
                    }
                }
            }

        }
    }
    
}


protocol PlaybackEngineDelegate {
    func didFinishPlaying()
    func didStartPlaying()
    func updateTime(currentTime: AVMusicTimeStamp)
    func didLoadBlock(block: MusicBlock)
    func didStartLoop()
    func didFinishLoop()
}

