//
//  PlaybackEngine.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

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
    private var engine = AVAudioEngine()
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)
    
    public var loadedBlock: MusicBlock? {
        didSet {
            delegate?.didLoadBlock(block: loadedBlock!)
        }
    }
    public var delegate: PlaybackEngineDelegate?
    public var bouncingDelegate: BouncingDelegate!
    private var timer: Timer?
    private var sequencer: AVAudioSequencer!
    private var data: Data?
    public var isPlaying = false
    public var isLooping = false
    private var mainMixerNode: AVAudioMixerNode!
    public var blockLength: AVMusicTimeStamp = 0
    public var tracks = [Track]()
    public var selectedTrack: Track!
    public enum trackType: Int {
        case instrument = 0, audio
    }
    
    
    override init() {
        super.init()
//        mainMixerNode = engine.mainMixerNode
//        let defaultTrack = Track(trackType: .instrument)
//        selectedTrack = defaultTrack
//        // attach track's mixer
//        engine.attach(defaultTrack.instrument!)
//        engine.attach(defaultTrack.mixer)
//        engine.connect(defaultTrack.instrument!, to: defaultTrack.mixer, format: audioFormat)
//        // connect track's mixer to main mixer
//        engine.connect(defaultTrack.mixer, to: engine.mainMixerNode, format: audioFormat)
//        self.tracks.append(defaultTrack)
        addObservers()
        setAudioSession()
    }
    
    private func setAudioSession() {
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
        musicBlock.loadPreset()
        self.configNewBlock(musicBlock: musicBlock)
    }
    
    
    func configNewBlock(musicBlock: MusicBlock) {
        self.blockLength = 0
        stopSequence()
        engine.stop()
        
        self.loadedBlock = musicBlock
        let newEngine = AVAudioEngine()
        setAudioSession()
        setSessionActive(true)
        let output = newEngine.outputNode
        self.mainMixerNode = newEngine.mainMixerNode
        newEngine.connect(mainMixerNode, to: output, format: audioFormat)
        let sampler = AVAudioUnitSampler()
        newEngine.attach(sampler)
        newEngine.connect(sampler, to: mainMixerNode, format: audioFormat)
        try! newEngine.start()
        self.sequencer = AVAudioSequencer(audioEngine: newEngine)
        self.engine = newEngine
        selectedTrack = nil
//        for i in tracks {
//            engine.detach(i.instrument!)
//            for e in i.effects {
//                engine.detach(e)
//            }
//            engine.detach(i.mixer)
//        }
        tracks = musicBlock.parsedTracks
        self.data = nil
        self.data = musicBlock.getSequenceData()
        if let data = self.data {
            do {
                try sequencer.load(from: data, options: .init(rawValue: 0))
                print("\(sequencer.tracks) tracks loaded, tempoTrack: \(sequencer.tempoTrack)")
            } catch {
                print("Failed load midiData! \(error)")
            }
            
            for i in 0 ..< tracks.count {
                if tracks[i].instrument == nil {
                    tracks[i].addToPlaybackEngine(trackType: .instrument)
                }
                tracks[i].trackIndex = i
                selectedTrack = tracks[i]
                engine.attach(tracks[i].instrument!)
                engine.attach(tracks[i].mixer)
                sequencer.tracks[i].destinationAudioUnit = tracks[i].instrument!
                if !tracks[i].effects.isEmpty {
                    for e in 0 ..< tracks[i].effects.count {
                        engine.attach(tracks[i].effects[e])
                        if e < tracks[i].effects.count - 1{
                            engine.connect(selectedTrack.effects[e], to: selectedTrack.effects[e+1], format: audioFormat)
                        }
                    }
                    engine.connect(tracks[i].instrument!, to: tracks[i].effects[0], format: audioFormat)
                    engine.connect(tracks[i].effects.last!, to: tracks[i].mixer, format: audioFormat)
                } else {
                    engine.connect(tracks[i].instrument!, to: tracks[i].mixer, format: audioFormat)
                }
                engine.connect(tracks[i].mixer, to: engine.mainMixerNode, format: audioFormat)
                if sequencer.tracks[i].lengthInBeats > blockLength {
                    blockLength = sequencer.tracks[i].lengthInBeats
//                    print(sequencer.tracks[i].lengthInBeats)
                }
            }
//            newEngine.disconnectNodeOutput(sampler)
//            newEngine.detach(sampler)
            sequencer.prepareToPlay()
        }
        if !self.engine.isRunning {
            startEngine()
        }
//        playSequence()
    }
    
    
    func updateBlock() {
        stopSequence()
        if let musicBlock = loadedBlock {
            self.sequencer = nil
            self.sequencer = AVAudioSequencer(audioEngine: engine)
            self.data = musicBlock.getSequenceData()
            if let data = self.data {
                do {
                    try sequencer.load(from: data, options: .init(rawValue: 0))
                    print("\(sequencer.tracks) tracks loaded, tempoTrack: \(sequencer.tempoTrack)")
                } catch {
                    print("Failed load midiData! \(error)")
                }
                for i in 0 ..< sequencer.tracks.count {
                    sequencer.tracks[i].destinationAudioUnit = tracks[i].instrument!
                }
            }
        }
    }
    
    func updateBlock(newBlock: MusicBlock) {
        stopSequence()
        guard loadedBlock != nil else {
            return
        }
        for (i,var v) in newBlock.parsedTracks.enumerated() {
            v.sequenceType = loadedBlock!.parsedTracks[i].sequenceType
            v.trackColor = loadedBlock!.parsedTracks[i].trackColor
            v.trackIndex = loadedBlock!.parsedTracks[i].trackIndex
            v.name = loadedBlock!.parsedTracks[i].name
            v.instrumentName = loadedBlock!.parsedTracks[i].instrumentName
        }
        newBlock.tempo = self.loadedBlock!.tempo
        self.loadedBlock = newBlock
        self.blockLength = newBlock.getBlockLength()
        self.sequencer = nil
        self.sequencer = AVAudioSequencer(audioEngine: engine)
        self.data = newBlock.getSequenceData()
        if let data = self.data {
            do {
                try sequencer.load(from: data, options: .init(rawValue: 0))
                print("\(sequencer.tracks) tracks loaded, tempoTrack: \(sequencer.tempoTrack)")
            } catch {
                print("Failed load midiData! \(error)")
            }
            for i in 0 ..< sequencer.tracks.count {
                sequencer.tracks[i].destinationAudioUnit = tracks[i].instrument!
                if sequencer.tracks[i].lengthInBeats > blockLength {
                    //                    print(sequencer.tracks[i].lengthInBeats)
                }
            }
        }
    }
    
    
    func setPlaybackRange(start: AVMusicTimeStamp, length: AVMusicTimeStamp) {
        stopSequence()
        stopLoop()
        sequencer.currentPositionInBeats = start
        let timePerQuarterNote = 60 / Double(loadedBlock!.tempo)
        let endTime = length * timePerQuarterNote
        let dispatchTime = DispatchTime.now() + endTime
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
            self.stopSequence()
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
                seq.tracks[i.trackIndex].destinationAudioUnit = i.instrument!
            }
            i.instrumentView = nil
            
            i.instrument!.auAudioUnit.requestViewController { [weak self] viewController in
                guard let strongSelf = self?.selectedTrack else {return}
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
                i.loopRange = AVBeatRange(start: 0, length: blockLength)
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
            guard self.sequencer != nil else {return}
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
    func restartSeq() {
        if let seq = sequencer {
            seq.currentPositionInBeats = AVMusicTimeStamp(0)
        }
    }
    func bounceCurrentBlock() {
        let bounceDir = STFileManager.shared.getBounceDir()
        let fullpath = bounceDir.appendingPathComponent(self.loadedBlock!.name).appendingPathExtension("wav")
        let mp3Path = bounceDir.appendingPathComponent(self.loadedBlock!.name).appendingPathExtension("mp3")
        let queue = DispatchQueue(label: "boucing")
        queue.async {
            do {
                try self.bounce(toFileURL: fullpath)
                guard FileManager.default.fileExists(atPath: fullpath.path) else {return}
                let converter = ExtAudioConverter()
                converter.inputFile = fullpath.path
                converter.outputFile = mp3Path.path
                converter.outputBitDepth = BitDepth_16
                converter.outputFormatID = kAudioFormatMPEGLayer3
                converter.outputFileType = kAudioFileMP3Type
                converter.convert()
                self.loadedBlock!.audioFile = mp3Path.path
                STFileManager.shared.deleteFile(atURL: fullpath)
                self.bouncingDelegate.BounceFinshed(path: mp3Path.path)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func getSequenceLengthInSec() -> Int {
        return Int(ceil(60 / Double(loadedBlock!.tempo) * blockLength))
        
    }
    
    func bounce(toFileURL fileURL: URL) throws {
        bouncingDelegate.startBoucing()
        self.stopSequence()
        self.stopLoop()
        let outputNode = self.mainMixerNode!
        let sequenceLength = self.sequencer.tracks.map({ $0.lengthInSeconds }).max() ?? 0
        var writeError: NSError? = nil
        let outputFile = try AVAudioFile(forWriting: fileURL, settings: outputNode.outputFormat(forBus: 0).settings)

        
        // Load the patches by playing the sequence through in preload mode.
//        self.sequencer.rate = 100.0
        self.sequencer.currentPositionInSeconds = 0
        self.sequencer.prepareToPlay()
        
        // Start recording.
        outputNode.installTap(onBus: 0, bufferSize: 4096, format: outputNode.outputFormat(forBus: 0)) { (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
            
            do {
                try outputFile.write(from: buffer)
            } catch {
                writeError = error as NSError
            }
            
        }
        
        // Add silence to beginning.
        usleep(200000)
        
        // Start playback.
        self.playSequence()
        
        // Continuously check for track finished or error while looping.
        while (self.sequencer.isPlaying
            && writeError == nil
            && self.sequencer.currentPositionInSeconds < sequenceLength) {
                usleep(100000)
        }
        
        // Ensure playback is stopped.
        self.sequencer.stop()
        
        // Add silence to end.
        usleep(1000000)
        
        // Stop recording.
        outputNode.removeTap(onBus: 0)
        
        // Return error if there was any issue during recording.
        if let writeError = writeError {
            throw writeError
        }
    }
    
    func stopBouncing() {
        self.sequencer.stop()
        self.mainMixerNode.removeTap(onBus: 0)
        let bounceDir = STFileManager.shared.getBounceDir()
        let fullpath = bounceDir.appendingPathComponent(self.loadedBlock!.name).appendingPathExtension("wav")
        STFileManager.shared.deleteFile(atURL: fullpath)
        bouncingDelegate.bounceStoped()
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: Selector(("engineConfigurationChange:")), name: NSNotification.Name.AVAudioEngineConfigurationChange, object: engine)
        
        NotificationCenter.default.addObserver(self, selector:Selector(("sessionInterrupted:")),name:NSNotification.Name.AVAudioSessionInterruption, object:engine)
        
        NotificationCenter.default.addObserver(self, selector:Selector(("sessionRouteChange:")), name:NSNotification.Name.AVAudioSessionRouteChange, object:engine)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioEngineConfigurationChange,object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
    }
    
    @objc func engineConfigurationChange(notification:NSNotification) {
        print("engine config change")
        startEngine()
        
        //userInfo is nil
        
        //        print("userInfo")
        //        print(notification.userInfo)
        
        if let userInfo = notification.userInfo as? Dictionary<String,Any?> {
            print("userInfo")
            print(userInfo)
        }
    }
    
    
    
    func sessionInterrupted(notification:NSNotification) {
        print("audio session interrupted")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = notification.userInfo as? Dictionary<String,Any?> {
            let reason = userInfo[AVAudioSessionInterruptionTypeKey] as! AVAudioSessionInterruptionType
            switch reason {
            case .began:
                print("began")
            case .ended:
                print("ended")
            }
        }
        
    }
    
    func sessionRouteChange(notification:NSNotification) {
        print("audio session route change \(notification)")
        
        if let userInfo = notification.userInfo as? Dictionary<String,Any?> {
            
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSessionRouteChangeReason {
                
                print("audio session route change reason \(reason)")
                
                switch reason {
                case .categoryChange: print("CategoryChange")
                case .newDeviceAvailable:print("NewDeviceAvailable")
                case .noSuitableRouteForCategory:print("NoSuitableRouteForCategory")
                case .oldDeviceUnavailable:print("OldDeviceUnavailable")
                case .override: print("Override")
                case .wakeFromSleep:print("WakeFromSleep")
                case .unknown:print("Unknown")
                case .routeConfigurationChange:print("RouteConfigurationChange")
                }
            }
            
            let previous = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
            print("audio session route change previous \(String(describing: previous))")
        }
        
        
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
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

protocol BouncingDelegate {
    func startBoucing()
    func BounceFinshed(path: String)
    func bounceStoped()
}
