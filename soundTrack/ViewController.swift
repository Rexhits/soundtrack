//
//  ViewController.swift
//  soundTrack
//
//  Created by WangRex on 7/18/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet var switcher: UIBarButtonItem!
    @IBOutlet var csoundConsole: UITextView!
    var playing = false
    var sequencer = STComposer.sequencer
    
    @IBAction func playPause(_ sender: UIBarButtonItem) {
        if playing {
            sequencer = STComposer.sequencer
            sequencer.stop()
            switcher.title = "Play"
            playing = false
        } else {
            STComposer.test()
            sequencer = STComposer.sequencer
            sequencer.csound.setMessageCallback(#selector(messageCallback), withListener: self)
            csoundConsole.text = ""
            switcher.title = "Stop"
            playing = true
        }
    }
    
    
    @IBAction func clear(_ sender: UIBarButtonItem) {
        csoundConsole.text = ""
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        sequencer.loadCSD()
//        let noteEvents = NoteEvents(note: [60, 64, 67, 71], velocity: [100, 80, 90, 70], duration: [0.25, 0.25, 0.25, 0.25])
//        let controllerEvent = ChannelEvent(status: .Controller, controllerNumber: 7, value: 100, reserved: nil)
//        sequencer.addTempoEvent(bpm: 60, startAt: 1)
//        sequencer.addTimeSignatureEvent(numerator: 4, denominator: 4, startAt: 0)
//        sequencer.addChannelEvent(event: controllerEvent, toTrack: 0, toChannel: 0, at: 0)
//        sequencer.addNoteEvents(events: noteEvents, toTrack: 0, toChannel: 0, startAt: 0)
////        let url = GlobalFunctions.getURLInDocumentDirectoryWithFilename(filename: "new.mid")
////        sleep(2)
////        sequencer.saveMIDIFile(fileURL: url)
//        
//        sequencer.start()
//        sequencer.loopTrack(musicTrack: sequencer.tracks[0])
////        sequencer.loopTrack(musicTrack: sequencer.tracks[1])
////        sequencer.loopTrack(musicTrack: sequencer.tracks[2])
////        sequencer.loopTrack(musicTrack: sequencer.tracks[3])
        
//
//        
//        print(GlobalFunctions.appDelegate.persistentContainer.persistentStoreDescriptions[0])
////        composer.test()
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        sequencer.stop()
        sequencer.csound.stop()
    }
    func updateUIWithNewMessage(newMessage: String) {
        let oldText = csoundConsole.text
        let fullText = oldText?.appending(newMessage)
        csoundConsole.text = fullText
    }
    func messageCallback (infoObj: NSValue) {
        var info = Message()
        infoObj.getValue(&info)
        let message = UnsafeMutablePointer<Int8>.allocate(capacity: 1024)
        vsnprintf(message, 1024, info.format, info.valist)
        let messageStr = String.init(format: "%s", message)
        DispatchQueue.main.async {
            self.updateUIWithNewMessage(newMessage: messageStr)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

