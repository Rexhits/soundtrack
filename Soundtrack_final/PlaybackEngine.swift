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
    var effectNodes = [AVAudioNode]()
    private var sequencer: AVAudioSequencer!
    public enum trackType {
        case instrument, audio
    }
    
    override init() {
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
        if let midiData = musicBlock.getSequenceData() {
            do {
                try sequencer.load(from: midiData, options: .init(rawValue: 1))
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
    
    func newNode(type: trackType, component: AVAudioUnit) {
        switch type {
        case .instrument:
            let instumentNode = component as! AVAudioUnitMIDIInstrument
            engine.attach(instumentNode)
            engine.connect(instumentNode, to: engine.mainMixerNode, format: audioFormat)
            self.instrumentsNodes.append(instumentNode)
        default:
            break
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
