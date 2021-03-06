//
//  MusicSequence.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/5/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import AudioToolbox
import SwiftyJSON
import Upsurge

protocol MusicalSequence: CustomStringConvertible {
    var attachTo: MusicBlock? {get set}
    var musicTrack: MusicTrack? {get set}
    var content: BasicMusicalStructure {get set}
    var description: String {get}
    var sequenceType: Int {get set}
    var measures: [Measure] {get}
    var asJson: JSON {get}
    init(json: JSON)
    init()
    mutating func addNote(note: NoteEvent)
    mutating func addArticulation(articulation: Articulation)
    mutating func addSequence(sequence: MusicalSequence)
    mutating func appendSequence(inputSequence: MusicalSequence)
    func getNoteMatrix() -> Matrix<Int>
    func getArticulationMatrix() -> String
    
}

extension MusicalSequence {
    
    var sequenceType: Int {
        get {
            return content.sequenceType
        }
        set {
            content.sequenceType = newValue
        }
    }
    
    var asJson: JSON {
        var json: JSON = [:]
        json["instrument"].string = self.instrumentName
        json["sequenceType"].int = self.sequenceType
        json["notes"].arrayObject = self.notes.map{$0.asJson}
        json["articulations"].arrayObject = self.articulations.map{$0.asJson}
        return json
    }
    
    var measures:[Measure] {
        get{
            return byMeasure()
        }
    }
    
    func getInfoJson() -> JSON {
        var json: JSON = [:]
        json["instrument"].string = self.instrumentName
        json["sequenceType"].int = self.sequenceType
        let (minPitch,maxPitch,meanPitch,medianPitch,standardDiviationOfPitch) = pitchAnalysis()
        json["minPitch"].double = minPitch
        json["maxPitch"].double = maxPitch
        json["meanPitch"].double = meanPitch
        json["medianPitch"].double = medianPitch
        json["standardDiviationOfPitch"].double = standardDiviationOfPitch
        let (groupNoteSeparation, groupPolyphonic, groupRepetition) = groupAnalysis()
        json["groupNoteSeparation"].double = groupNoteSeparation
        json["goupPolyphonic"].double = groupPolyphonic
        json["groupRepetion"].double = groupRepetition
        json["noteDistribution"].arrayObject = getNoteDistribution()
        json["rhythumPattern"].arrayObject = getRhythumPattern()
        return json
    }
    
    
    init(json: JSON) {
        self.init()
        guard let instrument = json["instrument"].string, let sequenceType = json["sequenceType"].int, let notes = json["notes"].array, let articulations = json["articulations"].array else {
            return
        }
        self.instrumentName = instrument
        self.sequenceType = sequenceType
        self.notes = notes.map{NoteEvent(json: $0)}
        self.articulations = articulations.map{Articulation(json: $0)}
    }
    
    var description: String {
        return String("\nInstrumentName:  \(instrumentName)\nTempo: \(tempo)\nTimeSignature: \(timeSignature)\nNotes: \(notes)\nArticulations: \(articulations)\n")
    }
    var trackNum: Int? {
        return nil
    }
    
    var musicTrack:MusicTrack? {
        get {return content.musicTrack}
        set {
            content.musicTrack = newValue
//            print("MusicTrack set \(self.content.musicTrack)")
        }
    }
    var attachTo: MusicBlock? {
        get {return content.attachTo}
        set {
            content.attachTo = newValue!
            self.timeSignature = newValue!.timeSignature
            self.tempo = newValue!.tempo
        }
    }
    
    var notes: [NoteEvent] {
        get {return content.notes}
        set {content.notes = newValue}
    }
    
    var tempo: Int {
        get {return content.tempo}
        set {content.tempo = newValue}
    }
    
    var articulations: [Articulation] {
        get {return content.articulations}
        set {content.articulations = newValue}
    }
    
    var timeSignature: TimeSignature {
        get {return content.timeSignature}
        set {content.timeSignature = newValue}
    }
    
    var instrumentName: String {
        get {return content.instrumentName}
        set {content.instrumentName = newValue}
    }
    
    var noteDistribution: [Int: [NoteEvent]] {
        get {return content.noteDistribution}
        set {content.noteDistribution = newValue}
    }
    
    mutating func addNote(note: NoteEvent) {
        notes.append(note)
        noteDistribution[note.pitchClass]?.append(note)
    }
    mutating func addArticulation(articulation: Articulation) {
        articulations.append(articulation)
    }
    mutating func addSequence(sequence: MusicalSequence) {
        for n in sequence.notes {
            self.addNote(note: n)
        }
        for a in sequence.articulations {
            self.addArticulation(articulation: a)
        }
    }
    
    mutating func appendSequence(inputSequence: MusicalSequence) {
        var endTime: MusicTimeStamp = 0
        if self.musicTrack != nil {
            endTime = getTrackLength()
            print("EndTime: \(endTime)")
        }
        for var i in inputSequence.notes {
            i.timeStamp += endTime
            if self.musicTrack != nil {
                addNoteEvent(track: self.musicTrack!, note: i)
                addNote(note: i)
            }
        }
        for var i in inputSequence.articulations {
            i.timeStamp += endTime
            if self.musicTrack != nil {
                addControllerEvent(track: self.musicTrack!, event: i)
                addArticulation(articulation: i)
            }
        }
        
    }
    
    private func addNoteEvent(track: MusicTrack, note: NoteEvent) {
        var noteMess = MIDINoteMessage(channel: 0, note: UInt8(note.note), velocity: UInt8(note.velocity), releaseVelocity: 0, duration: Float32(note.duration))
        let status = MusicTrackNewMIDINoteEvent(track, note.timeStamp, &noteMess)
        if status != OSStatus(noErr) {
//            print("error adding Note \(status)")
        } else {
//            print("new Note added: \(note)")
        }
    }
    
    private func addControllerEvent(track: MusicTrack, event: Articulation) {
        var messStatus = event.status
        switch messStatus {
        case 160 ... 175:
            messStatus = 161
        case 176 ... 201:
            messStatus = 177
        case 240 ... 255:
            messStatus = 241
        default:
            break
        }
        var ChannelMess = MIDIChannelMessage(status: event.status, data1: UInt8(event.controllerNum), data2: UInt8(event.value), reserved: 0)
        let status = MusicTrackNewMIDIChannelEvent(track, event.timeStamp, &ChannelMess)
        if status != OSStatus(noErr) {
            print("error adding Controller Message \(status)")
        } else {
            print("new Controller Message added: \(event)")
        }
    }
    func getTrackLength() -> MusicTimeStamp {
        let musicTrack = self.musicTrack!
        //The time of the last music event in a music track, plus time required for note fade-outs and so on.
        var trackLength = MusicTimeStamp(0)
        var tracklengthSize = UInt32(0)
        let status = MusicTrackGetProperty(musicTrack,
                                           UInt32(kSequenceTrackProperty_TrackLength),
                                           &trackLength,
                                           &tracklengthSize)
        if status != OSStatus(noErr) {
            print("Error getting track length \(status)")
            return 0
        }
        print("track length is \(trackLength)")
        return trackLength
    }
    
    
    func getNumOfMeasure() -> Int {
        let measureLength = timeSignature.lengthPerBeat/timeSignature.beatsPerMeasure * 4
        let length = getSequenceLength()
        guard length >= 1 else {
            return 1
        }
        if Float(measureLength).truncatingRemainder(dividingBy: Float(length)) != 0 {
            return Int(length / Double(measureLength)) + 1
        } else {
            return Int(length / Double(measureLength))
        }
    }
    
    
    
    func byMeasure() -> [Measure] {
        
        var sequence = [Measure]()
        let measureLength = timeSignature.lengthPerBeat/timeSignature.beatsPerMeasure * 4
        let quantizedNotes = quantize().notes
        let numOfMeasure = getNumOfMeasure()
        for i in 0 ..< numOfMeasure {
            let currentTime = i * measureLength
            let noteList = quantizedNotes.filter{(Double(currentTime) ..< Double(currentTime + measureLength)).contains($0.timeStamp)}
            let articulationList = articulations.filter{(Double(currentTime) ..< Double(currentTime + measureLength)).contains($0.timeStamp)}
            var newMeasure = Measure(notes: noteList, articulations: articulationList)
            newMeasure.content.tempo = self.tempo
            newMeasure.content.instrumentName = self.instrumentName
            newMeasure.timeSignature = self.timeSignature
            newMeasure.notes = newMeasure.notes.map({ n -> NoteEvent in
                var note = n
                let offset = Double(i) * Double(measureLength)
                note.timeStamp -= offset
                return note
            })
            if let attachTo = self.attachTo {
                newMeasure.attachTo = attachTo
            }
            sequence.append(newMeasure)
        }
        return sequence
    }
    
    func getNoteMatrix() -> Matrix<Int> {
        /// OutputMartixString, Format: Channel, TimeStamp, Note, Velocity, Duration
        
//        var output = [String]()
//        for i in notes {
//            output.append("\(String.init(format: "%2d", i.channel)) \t \(String.init(format: "%.2f", i.timeStamp)) \t \(String.init(format: "%3d", i.note)) \t \(String.init(format: "%3d", i.velocity)) \t \(String.init(format: "%.4f", i.duration))")
//        }
//        return output.joined(separator: "\n")
        var matrix = [[Int]]()
        let quantized = self.quantize()
        let length = ceil(getSequenceLength())
        var i: MusicTimeStamp = 0
        let oneTimeStep = 0.25
        while i <= length {
            var state = [Int].init(repeating: 0, count: 78)
            let now = i ..< i + oneTimeStep
            let notes_now = quantized.notes.filter({ (inNote) -> Bool in
                let overlap = inNote.timeRange.clamped(to: now)
                return !overlap.isEmpty
            })
            for n in notes_now {
                state[n.note] = n.velocity
            }
            matrix.append(state)
            i += oneTimeStep
        }
        return Matrix<Int>(matrix)
    }
    
    func getArticulationMatrix() -> String {
        var output = [String]()
        for i in articulations {
            output.append("\(i.status) \t \(String.init(format: "%.2f", i.timeStamp)) \t \(String.init(format: "%3d", i.controllerNum)) \t \(String.init(format: "%3d", i.value))")
        }
        return output.joined(separator: "\n")
    }
    
    
    func getBassPercentage() -> Double {
        let bassNotes = self.notes.filter({$0.note < 54})
        return Double(bassNotes.count) / Double(self.notes.count) * 100.0
    }
    

    
    private func getNoteInterval() -> [Int] {
        var intervalList = [Int]()
        guard notes.count > 1 else {
            return [0]
        }
        for i in 0 ..< notes.count - 1 {
            intervalList.append(notes[i + 1].note - notes[i].note)
        }
        intervalList.insert(0, at: 0)
        return intervalList
    }
    
    func getMeanOfNoteInterval() -> Double {
        let intervalList = self.getNoteInterval().map{abs($0)}
        let total = intervalList.reduce(0, +)
        return Double(total) / Double(self.notes.count)
    }
    
    func getMaxAndMinNoteInterval() -> (Int, Int) {
        let intervalList = self.getNoteInterval().map{abs($0)}
        return (intervalList.max()!, intervalList.min()!)
    }
    
    
    func getSequenceLength() -> MusicTimeStamp {
        return notes.last!.timeStamp + MusicTimeStamp(notes.last!.duration)
    }
    
    func getNoteGroups() -> [[NoteEvent]] {
        var i = 0
        var noteGroup = [[NoteEvent]]()
        while i < notes.count {
            var overlaps = 0
            let range = notes[i].timeRange
            var newGroup = [NoteEvent]()
            for item in (i + 1) ..< notes.count {
                if notes[item].timeRange.overlaps(range) {
                    newGroup.append(notes[i])
                    if notes[i].note != notes[item].note {
                        overlaps += 1
                        i += 1
                        newGroup.append(notes[item])
                    }
                }
            }
            if !newGroup.isEmpty {
                noteGroup.append(newGroup)
            }
            i += 1
        }
        
        return noteGroup
    }
    
    func pitchAnalysis() -> (min: Double, max: Double, mean: Double, median: Double, standardDiviation: Double) {
        let pitches = self.notes.flatMap{$0.note}
        let min = Double(pitches.min()!)
        let max = Double(pitches.max()!)
        let mean = Double(pitches.reduce(0, +)) / Double(pitches.count)
        
        func getMedian() -> Double{
            let sorted = pitches.sorted()
            if pitches.count % 2 == 1 {
                return Double(sorted[Int(floor(Double(pitches.count)/2))])
            } else if pitches.count % 2 == 0 && !pitches.isEmpty {
                return Double(sorted[pitches.count/2]+sorted[(pitches.count/2)-1])/2
            } else {
                return -Double(Int.max)
            }
        }
        
        let median = getMedian()
        let standardDiviation = (pitches.map{pow(Double($0) - mean, 2.0)}.reduce(0, +)) / Double(pitches.count)
        return (min, max, mean, median, standardDiviation)
    }
    
    func groupAnalysis() -> (noteSeparation: Double, Polyphonic: Double, Repetition: Double) {
        // all note groups
        let groups = getNoteGroups()

        // make sure is polyphonic, otherwise return 0
        
        guard groups.count > 1 else {
            return(0,0,0)
        }
        
        // all notes in each groups
        let notesInGroups = groups.map{$0.flatMap{$0.note}}
        let polyphonic = Double(notesInGroups.flatMap{$0.count}.reduce(0, +)) / Double(notesInGroups.count)
        let noteSeparationByGroups = notesInGroups.map{ input -> Double in
            var result = [Int]()
            for i in 1 ..< input.count {
                result.append(input[i] - input[i-1])
            }
            return Double(result.reduce(0, +)) / Double(result.count)
        }
        let noteSeparation = noteSeparationByGroups.reduce(0, +) / Double(groups.count)
        // analysis of pitch class on notes in each groups, from 0(c) - 11(b)
        let pitchClasses = notesInGroups.map{Set($0.map{$0 % 12}.sorted())}
        var similarities = [Double]()
        for i in 1 ..< pitchClasses.count {
            similarities.append(Double(pitchClasses[i].intersection(pitchClasses[i-1]).count) / Double(pitchClasses[i].count))
        }
        let repetition = similarities.reduce(0, +) / Double(similarities.count)
        return(noteSeparation, polyphonic, repetition)
    }
    
    func getNoteDistribution() -> [Double] {
        return noteDistribution.sorted(by: {$0.0 < $1.0}).map({Double($0.value.count) / Double(notes.count)})
    }
    
    func getMeanNoteLength() -> Double {
        return self.notes.map{$0.timeRange.upperBound - $0.timeRange.lowerBound}.reduce(0, +) / Double(self.notes.count)
    }
    
    
    func quantize() -> BasicMusicalStructure {
        var sequence = self.content
        let meanNoteLength = self.getMeanNoteLength()
        
        func getQuantizationStep() -> Double {
            if meanNoteLength > 0.5 {
                return 0.5
            } else {
                return 0.25
            }

        }
        
        let quantizationStep = getQuantizationStep()
        let quantizedTime = self.notes.map{$0.timeStamp}.map { (i) -> MusicTimeStamp in
            let ramianer = i.truncatingRemainder(dividingBy: quantizationStep)
            if ramianer < quantizationStep / 2 {
                return i - i.truncatingRemainder(dividingBy: quantizationStep)
            } else {
                return i - i.truncatingRemainder(dividingBy: quantizationStep) + quantizationStep
            }
        }
        for i in 0 ..< sequence.notes.count {
            sequence.notes[i].timeStamp = quantizedTime[i]
        }
        return sequence
    }
    
    func getMeanNoteOctave() -> Int {
        return lround(self.notes.map{Double($0.octave)}.reduce(0, +) / Double(self.notes.count))
    }
    
    
    
    func timestampAnalysis() -> [Measure] {
        var timestampSet = self.measures.map{Set($0.notes.flatMap{$0.timeStamp})}

        var similarity = [Double]()
        for i in 0 ..< timestampSet.count - 1{
            guard !timestampSet[i].isEmpty && !timestampSet[i+1].isEmpty else {
                similarity.append(0)
                continue
            }
            similarity.append(Double(timestampSet[i].intersection(timestampSet[i+1]).count) / Double(max(timestampSet[i].count, timestampSet[i+1].count)))
            
        }
        let patterns = similarity.enumerated().filter({$1 > 0.8}).map{$0.offset}
        return removeConcective(input: patterns).map{self.measures[$0]}
    }
    
    func getRhythumPattern() -> [[String: Any]] {
        let analysis = timestampAnalysis()
        var output = [[String: Any]]()
        for i in analysis {
            let dic: [String: Any] = ["timeStamp": i.notes.map{$0.timeStamp}, "velocity": i.notes.map{$0.velocity}, "note": i.notes.map{$0.note}, "duration": i.notes.map{$0.duration}]
            output.append(dic)
        }
        return output
    }
    
    
    
    func removeConcective(input: [Int]) -> [Int] {
        return input.enumerated().flatMap { index, element in
            return index > 0 && input[index - 1] + 1 == element ? nil : element
        }
    }
    
    
}

