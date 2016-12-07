//
//  IndexViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import UIKit
import Lockbox
import AudioToolbox

class IndexViewController: UIViewController {
    var sequence = Measure()

    @IBOutlet var csoundConsole: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.path(forResource: "test", ofType: "mid")
        let fileURL = NSURL(string: url!)
        let parser = MusicBlock(name: "test", composedBy: "ZZW", midiFile: fileURL!)
        
        sequence.addNote(note: NoteEvent(note: 60, velocity: 80, timeStamp: 0, duration: 1))
        sequence.addNote(note: NoteEvent(note: 64, velocity: 90, timeStamp: 0, duration: 2))
        print(sequence.getNoteMatrix())
        parser.parsedTracks[0].appendSequence(inputSequence: sequence)

        //        player.csound.setMessageCallback(#selector(messageCallback), withListener: self)
//        parser.parse()
//        let parsedTracks = parser.parsedTracks
//        let measures = parsedTracks[0].byMeasure()
        //        print(measures[0].getArticulationMatrix())
        
//        track.addSequence(sequence: parsedTracks[0])
//        block.addTracks(tracks: [track])
//        block.addTempoEvent(bpm: 130, startAt: 0)
//        let saveURL = getURLInDocumentDirectoryWithFilename(filename: "test.mid")
//        print(saveURL)
////        block.saveMIDIFile(fileURL: saveURL)
//        player = Player(sequence: block)
//        player.csound.setMessageCallback(#selector(messageCallback), withListener: self)
        // Do any additional setup after loading the view.
//        print(Player.getAvailableAUList(type: .instrument)[0].audioComponentDescription)
        
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logout(_ sender: UIButton) {
        print("Logged Out! \(Lockbox.archiveObject(nil, forKey: "Token")))")
        self.performSegue(withIdentifier: "logout", sender: self)
    }

    
    @IBAction func play(_ sender: UIButton) {
        
    }
    @IBAction func stop(_ sender: UIButton) {
//        player.csound.stop()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
