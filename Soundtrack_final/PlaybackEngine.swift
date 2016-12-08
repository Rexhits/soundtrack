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
    var instrumentsNodes = [AVAudioUnitMIDIInstrument]()
    var effectNodes = [AVAudioUnitEffect]()
    private var sequencer: AVAudioSequencer!
    private var data: Data?
    private var isPlaying = false
    public var mainMixerNode: AVAudioMixerNode!
    public var selectedUnit: AUAudioUnit?
    public var selectedNode: AVAudioUnit?
    public var selectedNodeDescription: AudioComponentDescription?
    var selectedUnitPreset = [AUAudioUnitPreset]()
    public enum trackType: Int {
        case instrument = 0, audio
    }
    
    
    
    override init() {
        mainMixerNode = engine.mainMixerNode
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
        sequencer = AVAudioSequencer(audioEngine: engine)
        self.data = musicBlock.getSequenceData()
        if let data = self.data {
            do {
                try sequencer.load(from: data, options: .init(rawValue: 1))
            } catch {
                print("Failed load midiData! \(error)")
            }
            
            for i in sequencer.tracks {
                i.destinationAudioUnit = instrumentsNodes[0]
//                newNode(type: .instrument, component: AVAudioUnit)
            }
            sequencer.prepareToPlay()
        }
        startEngine()
    }
    
    func addNode(type: trackType, _ cd: AudioComponentDescription?, completionHandler: @escaping ((Void) -> Void)) {
        func done() {
            if type == .instrument {
                if sequencer != nil && isPlaying {
                    try! sequencer.start()
                }
            }
            completionHandler()
        }
        self.engine.connect(self.engine.mainMixerNode, to: self.engine.outputNode, format: audioFormat)
        if isPlaying {
            sequencer.stop()
        }
        if selectedNode != nil {
            engine.disconnectNodeInput(engine.mainMixerNode)
            engine.detach(selectedNode!)
            selectedNode = nil
        }
        if let componentDescription = cd {
            AVAudioUnit.instantiate(with: componentDescription, options: []) { avAudioUnit, error in
                guard let avAudioUnit = avAudioUnit else { return }
                self.selectedNode = avAudioUnit
                self.engine.attach(avAudioUnit)
                if type == .instrument {
                    self.engine.connect(avAudioUnit, to: self.engine.mainMixerNode, format: self.audioFormat)
                    self.instrumentsNodes.append(avAudioUnit as! AVAudioUnitMIDIInstrument)
                } else {
                    // code for effect node
                }
                self.selectedUnit = avAudioUnit.auAudioUnit
                self.selectedUnitPreset = avAudioUnit.auAudioUnit.factoryPresets ?? []
                self.selectedNodeDescription = cd
                done()
            }
        } else {
            done()
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
        
    }
    public func stopSequence() {
        self.sequencer.stop()
    }
    
    func getEngine() -> AVAudioEngine {
        return self.engine
    }
    
}
