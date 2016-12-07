//
//  PlaybackEngine.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/5/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox
import AVFoundation



class PluginManager: NSObject {
    
    
    /// Synchronizes starting/stopping the engine and scheduling file segments.
    private let stateChangeQueue = DispatchQueue(label: "SimplePlayEngine.stateChangeQueue")
    
    /// Serializes all access to `availableAudioUnits`.
    private let availableAudioUnitsAccessQueue = DispatchQueue(label: "SimplePlayEngine.availableAudioUnitsAccessQueue")
    
    
    /// Callback to tell UI when new components are found.
    private let componentsFoundCallback: ((Void) -> Void)?
    
    /// List of available instrument audio unit components.
    public var _availableInstruments = [AVAudioUnitComponent]()
    
    /// List of available effect audio unit components.
    public var _availableEffects = [AVAudioUnitComponent]()
    
    /**
     `self._availableInstruments` is accessed from multiple thread contexts. Use
     a dispatch queue for synchronization.
     */
    var availableInstruments: [AVAudioUnitComponent] {
        get {
            var result: [AVAudioUnitComponent]!
            
            availableAudioUnitsAccessQueue.sync {
                result = self._availableInstruments
            }
            
            return result
        }
        
        set {
            availableAudioUnitsAccessQueue.sync {
                self._availableInstruments = newValue
            }
        }
    }
    
    
    /**
     `self._availableEffects` is accessed from multiple thread contexts. Use
     a dispatch queue for synchronization.
     */
    var availableEffects: [AVAudioUnitComponent] {
        get {
            var result: [AVAudioUnitComponent]!
            
            availableAudioUnitsAccessQueue.sync {
                result = self._availableEffects
            }
            
            return result
        }
        
        set {
            availableAudioUnitsAccessQueue.sync {
                self._availableEffects = newValue
            }
        }
    }
    
    public init(componentsFoundCallback inComponentsFoundCallback: ((Void) -> Void)? = nil) {
        

        componentsFoundCallback = inComponentsFoundCallback
        super.init()
        if componentsFoundCallback != nil {
            // Only bother to look up components if the client provided a callback.
            updateAudioUnitList()
            // Sign up for a notification when the list of available components changes.
            NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: kAudioComponentRegistrationsChangedNotification as String as String), object: nil, queue: nil) { [weak self] _ in
                self?.updateAudioUnitList()
            }
        }
        
    }
    /**
     This is called from init and when we get a notification that the list of
     available components has changed.
     */
    private func updateAudioUnitList() {
        DispatchQueue.global(qos: .default).async {
            /*
             Locating components can be a little slow, especially the first time.
             Do this work on a separate dispatch thread.
             
             Make a component description matching any AU of the type.
             */
            var componentDescription = AudioComponentDescription()
            componentDescription.componentType = kAudioUnitType_MusicDevice
            componentDescription.componentSubType = 0
            componentDescription.componentManufacturer = 0
            componentDescription.componentFlags = 0
            componentDescription.componentFlagsMask = 0
            
            var componentDescription2 = AudioComponentDescription()
            componentDescription2.componentType = kAudioUnitType_Effect
            componentDescription2.componentSubType = 0
            componentDescription2.componentManufacturer = 0
            componentDescription2.componentFlags = 0
            componentDescription2.componentFlagsMask = 0
            self.availableInstruments = AVAudioUnitComponentManager.shared().components(matching: componentDescription)
            self.availableEffects = AVAudioUnitComponentManager.shared().components(matching: componentDescription2)
            // Let the UI know that we have an updated list of units.
            DispatchQueue.main.async {
                self.componentsFoundCallback!()
            }
        }
    }
    
    // MARK: Preset Selection
    

    public func selectAudioUnitWithComponentDescription(_ componentDescription: AudioComponentDescription?, completionHandler: @escaping ((_ auadiounit: AUAudioUnit, _ node: AVAudioUnit, _ preset:[AUAudioUnitPreset]) -> Void)) {
        var audioUnitnode: AVAudioUnit!
        var audioUnit: AUAudioUnit!
        var presetList = [AUAudioUnitPreset]()
        // Internal function to resume playing and call the completion handler.
        func done() {
            completionHandler(audioUnit, audioUnitnode, presetList.uniqueElements)
        }
        
        
        // Insert the audio unit, if any.
        if let componentDescription = componentDescription {
            AVAudioUnit.instantiate(with: componentDescription, options: []) { avAudioUnit, error in
                guard let avAudioUnit = avAudioUnit else { return }
                audioUnitnode = avAudioUnit
                audioUnit = avAudioUnit.auAudioUnit
                presetList = avAudioUnit.auAudioUnit.factoryPresets ?? []
                done()
            }
        } else {
            done()
        }
    }
    
    
}
