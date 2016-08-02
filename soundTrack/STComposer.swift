//
//  Composer.swift
//  soundTrack
//
//  Created by WangRex on 7/19/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation



struct Tonality {
    private let rootNotes = ["C", "#C/bD", "D", "#D/bE" ,"E", "F", "#F/bG", "G", "#G/bA", "A", "#A/bB", "B"]
    var root: String = "C"
//    var scale = Modes.allModes["Major"]!["Natural"]!
    init(transpose: Int, mode: [Int]) {
        if transpose > 11 && transpose < 0 {
            print("invalid transpose")
        } else {
            root = rootNotes[transpose]
//            scale = mode
        }
        
    }
}



struct TimeSignature {
    let numerator: UInt8
    let denominator:UInt8
}

//struct Pharse: MusicPiece {
//    let notes: NoteEvents
//    
//    
//}




struct MusicPiece {
    // Tempo of a piece
    var tempo = 120
    // Time Signature of a piece
    var timeSignature: TimeSignature = TimeSignature(numerator: 4, denominator: 4)
    // tonality of a piece
//    var tonality: Tonality = Tonality(transpose: 0, mode: Modes.allModes["Major"]!["Natural"] as! [Int])
    // Length of a piece
    let length: Int = 64
    // Instuments that been used in a piece
    let instruments: [Int]
    // Mood of the piece
    var mood: Int = 50
    // The create time of a piece
    private let createTime: NSDate = NSDate()
    // The name of the piece
    let name:String = "Defalut"
}


protocol Musician: ScoreManager {
    // Instrument a musician plays
    var instrument: Int {get}
    // Mood of a musician
    var mood: Int {get set}
    // Proficiency of playing the instrument
    var techinque: Int {get set}
    // Articulations that a musician can play, e.g. trill, mute, glissando...
    var articulations: [Int] {get}
}

struct Composer: ScoreManager {
    var mood: Float
}

class STComposer {
    static let compoer = Composer(mood: 5.0)
    static var sequencer = STSequencer()
    
    static func test() {
        
        sequencer.stop()
        sequencer = STSequencer()
        let mode = STComposer.compoer.randomChooseMode()
        print("scale: \(mode.scale!.upgoing)")
//        sequencer.addTimeSignatureEvent(numerator: 4, denominator: 4, startAt: 0)
        sequencer.addTempoEvent(bpm: 130, startAt: 0)
    

        print("endAt: \(sequencer.addNoteEvents(events: self.newNoteEventList(mode: mode), toTrack: 0, toChannel: 0, startAt: 0))")
        print("endAt: \(sequencer.addNoteEvents(events: self.newNoteEventList(mode: mode), toTrack: 0, toChannel: 1, startAt: 0))")

                
        sequencer.start()

    }
    static func newNoteEventList(mode: Mode) -> NoteEvents {
        let scale = mode.scale!
        var notes = [UInt8]()
        var velocity = [UInt8]()
        var duration = [Float32]()
        var notesToUse = [Int]()
        notesToUse = (scale.upgoing! as! [Int]).map{note in note + 36}
        let velList = [0, 60, 80, 120]
        let lengthList = [0.25,0.333, 0.5, 0.75, 1.0, 1.5]
        for _ in 0 ..< 200 {
            notes.append(UInt8(notesToUse[Int.random(input: notesToUse.count)] + (12 * (Int.random(input: 4)))))

            velocity.append(UInt8(velList[Int.randomIndex(probabilities: [10, 30, 30, 30])]))
            duration.append(Float32(lengthList[Int.randomIndex(probabilities: [25, 5, 30, 20, 15, 5])]))
        }
        print("seq: \(notes)")
        return NoteEvents(note: notes, velocity: velocity, duration: duration)
    }

}

protocol ScoreManager {
    var mood: Float {get set}
    func chooseMode(category: String, subCategory: String?, name: String) -> Mode
    func randomChooseMode() -> Mode
//    func newMood()
//    func generateTimeSignature()
//    func generatePhrase()
//    func Line(min: Float, middlePoints:[Float], max: Float, time: Float)
}

extension ScoreManager {
    
    var mood: Float {
        return 5.0
    }


    func chooseMode(category: String, subCategory: String?, name: String) -> Mode {
        let result = DataManager.getMode(category: category, subCategory: subCategory, name: name)
        return result.first!
    }
    
    func randomChooseMode() -> Mode {
        switch mood {
        case 0 ..< 3:
            let category = fetchRandomMode(list: ["Major", "Minor", "Medieval"], probabilities: [20, 70, 10])
            switch category {
            case (0, _):
                return getMode(modes: category.1, probabilities: [15, 60, 25])
            case (1, _):
                return getMode(modes: category.1, probabilities: [5, 80, 15])
            default:
                return getMode(modes: category.1, probabilities: [0,40, 25, 0, 0, 25, 10])
            }
        case 3 ..< 7:
            let category = fetchRandomMode(list: ["Major", "Minor", "Medieval", "Chinese"], probabilities: [30, 20, 25, 25])
            switch category {
            case (0, _):
                return getMode(modes: category.1, probabilities: [80, 15, 5])
            case (1, _):
                return getMode(modes: category.1, probabilities: [20, 65, 15])
            case (3, _):
                return getMode(modes: category.1, probabilities: [20, 20, 10, 20, 20, 10, 0])
            default:
                return getMode(modes: category.1, probabilities: nil)
            }
        case 7 ..< 10:
            let category = fetchRandomMode(list: ["Major", "Minor", "Medieval", "Chinese"], probabilities: [40, 10, 25, 25])
            switch category {
            case (0, _):
                return getMode(modes: category.1, probabilities: [80, 15, 5])
            case (1, _):
                return getMode(modes: category.1, probabilities: [20, 65, 15])
            case (3, _):
                return getMode(modes: category.1, probabilities: [20, 10, 15, 25, 30, 10, 0])
            default:
                return getMode(modes: category.1, probabilities: nil)
            }
        default:
            print("Mood is not set properly, should between 0 - 9")
            return chooseMode(category: "Major", subCategory: nil, name: "Natural")
        }
    }
    func fetchRandomMode(list: [String], probabilities: [Double]) -> (Int, [Mode]) {
        let categoryChoice = Int.randomIndex(probabilities: probabilities)
        let result = DataManager.getModesbyCategory(category: list[categoryChoice])
        return (categoryChoice, result)
    }
    func getMode(modes: [Mode], probabilities: [Double]?) -> Mode {
        var choice = Int()
        if probabilities != nil {
            choice = Int.randomIndex(probabilities: probabilities!)
        } else {
            choice = Int.random(input: (modes.count - 1))
        }
        print("Category: \(modes[choice].category!)")
        print("Subcategory: \(modes[choice].subCategory)")
        print("Name: \(modes[choice].name!)")
        return modes[choice]
    }
}



