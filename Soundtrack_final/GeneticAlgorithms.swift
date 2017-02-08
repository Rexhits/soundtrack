//
//  GeneticAlgorithms.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/28/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AIToolbox


class Evolution {
    static let shared = Evolution()
    var mainBlock: MusicBlock! {
        didSet {
            // hard code track1 for test
//            mainCandidates.append(contentsOf: mainBlock.parsedTracks[0].getPitchClass())
        }
    }
    var secondBlock: MusicBlock! {
        didSet {
            // hard code track1 for test
//            secondCandidates.append(contentsOf: secondBlock.parsedTracks[0].getPitchClass())
        }
    }
    
    
    var mainCandidates = [NoteEvent]()
    
    var secondCandidates = [NoteEvent]()
    
    init(mainBlock: MusicBlock) {
        self.mainBlock = mainBlock
    }
    
    init() {
        
    }
    
    
    func chooseFromMainBlock(timeStamp: Double) -> NoteEvent {
        let i = Int(arc4random_uniform(UInt32(mainCandidates.count)))
        
        let octave = Int.random(range: 5...7)
        var newNote = mainCandidates[i]
        newNote.note = newNote.note + (12 * octave)
        newNote.timeStamp = timeStamp
        return newNote
    }
    
    func chooseFromSecondBlock(timeStamp: Double) -> NoteEvent {
        let i = Int(arc4random_uniform(UInt32(secondCandidates.count)))
        let octave = Int.random(range: 5...7)
        var newNote = secondCandidates[i]
        newNote.note = newNote.note + (12 * octave)
        newNote.timeStamp = timeStamp
        return newNote
    }
    
    func generateNewContent() -> MusicBlock {
        var currentTimeStamp = Double(0)
        let newContent = MusicBlock()
        var track = Track()
        for _ in 0 ..< 50 {
            let random = Double(arc4random() % 1000) / 10.0
            switch random {
            case 0 ..< 75:
                let newNote = chooseFromMainBlock(timeStamp: currentTimeStamp)
                track.addNote(note: newNote)
                currentTimeStamp += newNote.duration
            default:
                let newNote = chooseFromSecondBlock(timeStamp: currentTimeStamp)
                track.addNote(note: newNote)
                currentTimeStamp += newNote.duration
            }
        }
        newContent.addTrack(track: track)
        return newContent
    }
}
