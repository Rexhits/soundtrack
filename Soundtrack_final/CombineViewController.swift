//
//  CombineView.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/13/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Charts

class CombineViewController: UIViewController {
    
    @IBOutlet weak var lineChart: UIView!
    @IBOutlet weak var mainChart: ChartViewForCombine!
    @IBOutlet weak var auxChart: ChartViewForCombine!
    
    @IBOutlet weak var line: LineChartView!
    
    var piece: Piece!
    
    var mainBlock: MusicBlock!
    
    var auxBlock: MusicBlock!
    
    let mainColor = UIColor.hexStringToUIColor(hex: "#ff5079")
    let auxColor = UIColor.hexStringToUIColor(hex: "#5079ff")
    
    var newBlock: MusicBlock!
    
    var delegate: CombineVCDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        prepareData()
        setupLineChart()
//        mainChart.isHidden = true
//        auxChart.isHidden = true
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragged(sender:)))
        self.line.addGestureRecognizer(panGesture)
    }
    
    override func viewDidLayoutSubviews() {
        
    }
    
    func prepareData() {
        let maxLength = round(max(mainBlock.getBlockLength(), auxBlock.getBlockLength())) / Double(mainBlock.timeSignature.beatsPerMeasure)
        mainChart.data = getDataFromBlock(block: mainBlock)
        auxChart.data = getDataFromBlock(block: auxBlock)
        mainChart.backgroundColor = mainColor
        auxChart.backgroundColor = auxColor
        mainChart.xAxis.axisMaximum = maxLength
        auxChart.xAxis.axisMaximum = maxLength
        mainChart.xAxis.drawLabelsEnabled = false
        auxChart.xAxis.drawLabelsEnabled = false
        mainChart.xAxis.gridColor = UIColor.white
        mainChart.leftAxis.gridColor = UIColor.lightText
        auxChart.xAxis.gridColor = UIColor.white
        auxChart.leftAxis.gridColor = UIColor.lightText
    }
    
    func dragged(sender: UIPanGestureRecognizer) {
        if sender.numberOfTouches > 0 {
            let pos = sender.location(ofTouch: 0, in: self.line)
            if pos.y >= 0 && pos.y <= self.line.frame.maxY && pos.x >= 10 && pos.x <= self.line.frame.maxX - 10 {
                let x = pos.x - 10
                let width = self.line.bounds.width - 10
                let i = Int(floor(x / width * CGFloat(line.data!.entryCount)))
                let value = (0.5 - (pos.y / line.frame.maxY)) * 2
                let entry = line.data!.dataSets.first!.entryForIndex(i)!
                entry.y = Double(value)
                line.notifyDataSetChanged()
            }
        }
        
    }
    
    func getLineData() -> [Double]{
        let last = line.data!.dataSets.first!.entryCount - 1
        var outData = [Double].init(repeating: 0, count: last * 4)
        var i: Int = 0
        var start: Double = 0
        var end: Double = 0
        var step:Double = 0
        while i < outData.count {
            if i % 4 == 0 {
                start = line.data!.dataSets.first!.entryForIndex(i / 4)!.y
                
                end = line.data!.dataSets.first!.entryForIndex(i / 4 + 1)!.y
                
                step = (end - start) / 4.0
            }
            outData[i] = start
            start += step
            i += 1
        }
        outData.append(line.data!.dataSets.first!.entryForIndex(last)!.y)
        return outData
    }
    
    func setupLineChart() {
        let maxLength = Int(round(max(mainBlock.getBlockLength(), auxBlock.getBlockLength())))
        let dataEntry = (0 ... maxLength).map{ChartDataEntry(x: Double($0), y: 0)}
        let dataSet = LineChartDataSet(values: dataEntry, label: nil)
        dataSet.drawValuesEnabled = false
        dataSet.setCircleColor(UIColor.yellow.withAlphaComponent(0.5))
        dataSet.setColor(UIColor.yellow.withAlphaComponent(0.7))
        
        let data = LineChartData(dataSet: dataSet)
        line.data = data
        line.leftAxis.axisMinimum = -1
        line.leftAxis.axisMaximum = 1
        line.xAxis.enabled = false
        line.legend.enabled = false
        line.leftAxis.enabled = false
        line.rightAxis.enabled = false
        line.chartDescription?.text = ""
        line.scaleXEnabled = false
        line.scaleYEnabled = false
//        line.highlighter = nil
        line.dragEnabled = true
        line.doubleTapToZoomEnabled = false
        line.minOffset = 10
    }
    
    func getDataFromBlock(block: MusicBlock) -> ScatterChartData{
        let notes = block.getAllNotes()
        let data = notes.map { (note) -> ChartDataEntry in
            let beatsPerMeasure = Double(block.timeSignature.beatsPerMeasure)
            return ChartDataEntry(x: note.noteEvent.timeStamp / beatsPerMeasure, y: Double(note.noteEvent.note))
        }
        let color = notes.map { (note) -> UIColor in
            let velocity = CGFloat(note.noteEvent.velocity)
            return UIColor.white.withAlphaComponent(velocity / 128)
        }
        let chartDataSet = ScatterChartDataSet(values: data)
        chartDataSet.drawValuesEnabled = false
        chartDataSet.shapeRenderer = CircleShapeRenderer()
        chartDataSet.scatterShapeSize = 5
        chartDataSet.colors = color
        let chartData = ScatterChartData(dataSet: chartDataSet)
        return chartData
        
    }

    @IBAction func previewTapped(_ sender: UIButton) {
        PlaybackEngine.shared.stopSequence()
        let numOfBars = line.data?.dataSets.first?.entryCount
        newBlock = self.mainBlock.composeNewContent(numOfBar: numOfBars! - 1, inputBlock: self.auxBlock, possibilityList: getLineData())
        PlaybackEngine.shared.updateBlock(newBlock: newBlock)
        PlaybackEngine.shared.playSequence()
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        if self.newBlock == nil {
            let numOfBars = line.data?.dataSets.first?.entryCount
            newBlock = self.mainBlock.composeNewContent(numOfBar: numOfBars! - 1, inputBlock: self.auxBlock, possibilityList: getLineData())
        }
        let clip = Clip(length: newBlock.getBlockLength(), data: newBlock.getSequenceData()! as NSData, fromMainBlock: nil)
        clip.timeSignature = "\(newBlock.timeSignature.lengthPerBeat)/\(newBlock.timeSignature.beatsPerMeasure)"
        clip.tempo = Int16(newBlock.tempo)
        clip.key = Int16(newBlock.key)
        clip.inPiece = piece
        clip.userComposed = true
        appDelegate.saveContext()
        self.delegate?.clipCreated()
    }
    @IBAction func backTapped(_ sender: UIButton) {
        self.delegate?.willExit()
    }
    
    @IBAction func resetTapped(_ sender: UIButton) {
        let dataSet = line.data!.dataSets.first!
        for i in 0 ..< dataSet.entryCount {
            dataSet.entryForIndex(i)!.y = 0
            line.notifyDataSetChanged()
        }
    }
    
    @IBAction func softTapped(_ sender: UIButton) {
        let dataSet = line.data!.dataSets.first!
        let point1: (Double, Double) = (0,0.5), point2: (Double, Double) = (Double(dataSet.entryCount - 1), -0.5)
        let (k,b) = line(point1: point1, point2: point2)
        for i in 0 ..< dataSet.entryCount {
            dataSet.entryForIndex(i)!.y = k * dataSet.entryForIndex(i)!.x + b
            line.notifyDataSetChanged()
        }
    }
    @IBAction func moderateTapped(_ sender: UIButton) {
        let dataSet = line.data!.dataSets.first!
        for i in 0 ..< dataSet.entryCount {
            dataSet.entryForIndex(i)!.y = sinWave(x: dataSet.entryForIndex(i)!.x, amp: 0.5)
            line.notifyDataSetChanged()
        }
    }
    
    @IBAction func extremeTapped(_ sender: UIButton) {
        let dataSet = line.data!.dataSets.first!
        let sq = square(amp: 1, length: dataSet.entryCount)
        for i in 0 ..< dataSet.entryCount {
            dataSet.entryForIndex(i)!.y = sq[i]
            line.notifyDataSetChanged()
        }
    }
    
    func line(point1:(Double, Double), point2:(Double, Double)) -> (Double, Double) {
        let (x1, y1) = point1, (x2, y2) = point2
        let k = (y2 - y1) / (x2 - x1)
        let b = y1 - k * x1
        return (k,b)
    }
    
    func sinWave(x: Double, amp: Double) -> Double {
        return sin(x) * amp
    }
    func square(amp: Double, length: Int) -> [Double] {
        var out = [Double].init(repeating: 0, count: length)
        var v = amp
        var i = 0
        for n in 0 ..< out.count {
            out[n] = v
            if length <=  2 * mainBlock.timeSignature.beatsPerMeasure {
                v *= -1
            } else {
                if i == mainBlock.timeSignature.beatsPerMeasure {
                    v *= -1
                    i = 0
                }
            }
            i += 1
        }
        return out
    }
}



class ChartViewForCombine: ScatterChartView {
    override func layoutSubviews() {
        self.chartDescription?.text = ""
        self.isUserInteractionEnabled = false
        self.highlighter = nil
        self.rightAxis.enabled = false
        //        self.xAxis.drawGridLinesEnabled = false
        //        self.drawGridBackgroundEnabled = false
        
        //        self.xAxis.drawLabelsEnabled = false
        self.xAxis.drawAxisLineEnabled = false
        self.xAxis.drawGridLinesEnabled = false
        self.xAxis.labelPosition = .bottom
        self.xAxis.labelTextColor = .white
        //        self.drawBordersEnabled = false
        //            self.leftAxis.drawGridLinesEnabled = false
        self.leftAxis.drawAxisLineEnabled = false
        self.leftAxis.drawLabelsEnabled = false
        self.minOffset = 10
        self.legend.enabled = false
        self.xAxis.axisMinimum = 0
        let max = ceil(self.data!.xMax)
        //        let beatsPerMeasure = Double(PlaybackEngine.shared.loadedBlock!.timeSignature.beatsPerMeasure)
        //        if self.data!.xMax.truncatingRemainder(dividingBy: beatsPerMeasure) != 0 {
        //            max = self.data!.xMax + self.data!.xMax.truncatingRemainder(dividingBy: beatsPerMeasure)
        //        } else {
        //            max = self.data!.xMax
        //        }
        self.xAxis.labelCount = Int(max)
    }
}


extension MusicBlock {
    class NoteOnTrack {
        var noteEvent: NoteEvent!
        var onTrack: Int!
        var trackType: Int!
        init(noteEvent: NoteEvent, onTrack: Int, trackType: Int) {
            self.noteEvent = noteEvent
            self.onTrack = onTrack
            self.trackType = trackType
        }
    }
    
    func getAllNotes() -> [NoteOnTrack] {
        var noteInCurrentBlock = [NoteOnTrack]()
        for i in parsedTracks.enumerated() {
            for n in i.element.quantize().notes {
                let note = NoteOnTrack(noteEvent: n, onTrack: i.offset, trackType: i.element.sequenceType)
                noteInCurrentBlock.append(note)
            }
        }
        let noteInCurrentBlock_sorted = noteInCurrentBlock.sorted(by: {$0.0.noteEvent.timeStamp < $0.1.noteEvent.timeStamp})
        return noteInCurrentBlock_sorted
    }
    
    func getAllNotes(secondBlock: MusicBlock) -> ([NoteOnTrack], [NoteOnTrack]) {
        var noteInCurrentBlock = [NoteOnTrack]()
        var noteInSecondBlock = [NoteOnTrack]()
        for i in parsedTracks.enumerated() {
            for n in i.element.quantize().notes {
                let note = NoteOnTrack(noteEvent: n, onTrack: i.offset, trackType: i.element.sequenceType)
                noteInCurrentBlock.append(note)
            }
        }
        for i in secondBlock.parsedTracks.enumerated() {
            for var n in i.element.quantize().notes {
                let keyOffset = secondBlock.key - self.key
                if i.element.sequenceType != 3 {
                    n.note += keyOffset
                    if n.note < noteLowerBound {
                        n.note += 12
                    } else if n.note > noteUpperBound {
                        n.note -= 12
                    }
                }
                let note = NoteOnTrack(noteEvent: n, onTrack: i.offset, trackType: i.element.sequenceType)
                noteInSecondBlock.append(note)
            }
        }
        let noteInCurrentBlock_sorted = noteInCurrentBlock.sorted(by: {$0.0.noteEvent.timeStamp < $0.1.noteEvent.timeStamp})
        let noteInSecondBlock_sorted = noteInSecondBlock.sorted(by: {$0.0.noteEvent.timeStamp < $0.1.noteEvent.timeStamp})
        //        print((noteInCurrentBlock_sorted.map{($0.onTrack, $0.noteEvent.timeStamp)}), (noteInSecondBlock_sorted.map{($0.onTrack, $0.noteEvent.timeStamp)}))
        return (noteInCurrentBlock_sorted, noteInSecondBlock_sorted)
    }
    
    func composeNewContent(numOfBar: Int, inputBlock: MusicBlock, step: Double, maxMutaitonChance: Double) -> MusicBlock {
        let length = Double(numOfBar * self.timeSignature.beatsPerMeasure)
        let (mainSequence, auxSequence) = getAllNotes(secondBlock: inputBlock)
        let currentBlockLength = self.getBlockLength()
        let secondBlockLength = inputBlock.getBlockLength()
        let minLength = min(currentBlockLength, secondBlockLength)
        let newBlock = MusicBlock()
        var tracks = self.parsedTracks
        for var i in tracks {
            i.notes = [NoteEvent]()
            i.tempo = Int((self.tempo + inputBlock.tempo) / 2)
        }
        var moveStep = step
        var i:Double = 0
        var pointer:Double = 0
        while i < length {
            if pointer > minLength{
                moveStep *= -1
            }
            if pointer < 0 {
                moveStep *= -1
            }
            let currentPosition = i / length * maxMutaitonChance
            let notes = (mainSequence.filter{$0.noteEvent.timeStamp == pointer}, auxSequence.filter{$0.noteEvent.timeStamp == pointer})
            if !notes.0.isEmpty || !notes.1.isEmpty {
                let choice = makeDecision(input: notes, chanceOfMutation: currentPosition)
                for n in choice {
                    var note = n.noteEvent
                    changeTimeStamp(input: &note!, timestamp: i)
                    tracks[n.onTrack].addNote(note: note!)
                }
            }
            pointer += moveStep
            i += step
        }
        
        newBlock.addTracks(tracks: tracks)
        return newBlock
    }
    
    func composeNewContent(numOfBar: Int, inputBlock: MusicBlock, possibilityList: [Double]) -> MusicBlock {
        let length = Double(numOfBar * self.timeSignature.beatsPerMeasure)
        let (mainSequence, auxSequence) = getAllNotes(secondBlock: inputBlock)
        var currentBlockLength = self.getBlockLength()
        if currentBlockLength.truncatingRemainder(dividingBy: MusicTimeStamp(self.timeSignature.beatsPerMeasure)) != 0 {
            currentBlockLength += MusicTimeStamp(self.timeSignature.beatsPerMeasure) - currentBlockLength.truncatingRemainder(dividingBy: MusicTimeStamp(self.timeSignature.beatsPerMeasure))
        }
        var secondBlockLength = inputBlock.getBlockLength()
        if secondBlockLength.truncatingRemainder(dividingBy: MusicTimeStamp(self.timeSignature.beatsPerMeasure)) != 0 {
            secondBlockLength += MusicTimeStamp(self.timeSignature.beatsPerMeasure) - secondBlockLength.truncatingRemainder(dividingBy: MusicTimeStamp(self.timeSignature.beatsPerMeasure))
        }
        let newBlock = MusicBlock()
        var tracks = self.parsedTracks
        for var i in tracks {
            i.notes = [NoteEvent]()
            i.tempo = Int((self.tempo + inputBlock.tempo) / 2)
        }
        var mainMoveStep = 0.25
        var secondMoveStep = 0.25
        var i:Double = 0
        var mainPointer: Double = 0
        var secondPointer: Double = 0
        var t = 0
        while t <= Int(length) {
            if mainPointer > currentBlockLength || mainPointer < 0{
                mainMoveStep *= -1
            }
            
            if secondPointer > secondBlockLength || secondPointer < 0{
                secondMoveStep *= -1
            }
            
            let mutationChance = Double.remap(input: possibilityList[t], oldMin: -1, oldMax: 1, newMin: 1, newMax: 0)
            let notes = (mainSequence.filter{$0.noteEvent.timeStamp == mainPointer}, auxSequence.filter{$0.noteEvent.timeStamp == secondPointer})
            if !notes.0.isEmpty || !notes.1.isEmpty {
                let choice = makeDecision(input: notes, chanceOfMutation: mutationChance)
                for n in choice {
                    var note = n.noteEvent
                    changeTimeStamp(input: &note!, timestamp: i)
                    tracks[n.onTrack].addNote(note: note!)
                }
            }
            mainPointer += mainMoveStep
            secondPointer += secondMoveStep
            i += secondMoveStep
            t += 1
        }
        
        newBlock.addTracks(tracks: tracks)
        return newBlock
    }

    
    func changeTimeStamp(input: inout NoteEvent, timestamp: Double) {
        input.timeStamp = timestamp
    }
    
    func makeDecision(input:([NoteOnTrack], [NoteOnTrack]),chanceOfMutation: Double) -> [NoteOnTrack] {
        let dice = Double(arc4random() % 1000) / 10.0
        if (0 ..< chanceOfMutation * 100).contains(dice) {
            let notes = input.1
            for i in notes {
                let outputVelocity = i.noteEvent.velocity - Int(40.0 * (1 - chanceOfMutation))
                if outputVelocity < 10 {
                    i.noteEvent.velocity = 10
                } else {
                    i.noteEvent.velocity = outputVelocity
                }

            }
            return notes
        } else {
            for i in input.0 {
                let outputVelocity = i.noteEvent.velocity - Int(20.0 * chanceOfMutation)
                if outputVelocity < 10 {
                    i.noteEvent.velocity = 10
                } else {
                    i.noteEvent.velocity = outputVelocity
                }
            }
            return input.0
        }
    }
    
    func trackMapping(input:NoteOnTrack) -> Int? {
        switch input.trackType {
        case 0:
            let tracks = self.parsedTracks.filter{$0.sequenceType == 0}
            if !tracks.isEmpty {
                let trackNums = tracks.map{$0.trackIndex!}
                let index = Int(arc4random_uniform(UInt32(trackNums.count)))
                return trackNums[index]
            } else {
                return nil
            }
        case 1:
            let tracks = self.parsedTracks.filter{$0.sequenceType == 1}
            if !tracks.isEmpty {
                let trackNums = tracks.map{$0.trackIndex!}
                let index = Int(arc4random_uniform(UInt32(trackNums.count)))
                return trackNums[index]
            } else {
                return nil
            }
        case 2:
            let tracks = self.parsedTracks.filter{$0.sequenceType == 2}
            if !tracks.isEmpty {
                return tracks.map{$0.trackIndex!}.first!
            } else {
                return nil
            }
        default:
            let tracks = self.parsedTracks.filter{$0.sequenceType == 3}
            if !tracks.isEmpty {
                let trackNums = tracks.map{$0.trackIndex!}
                let index = Int(arc4random_uniform(UInt32(trackNums.count)))
                print(trackNums[index])
                return trackNums[index]
            } else {
                return nil
            }
        }
    }
    
}

protocol CombineVCDelegate {
    func clipCreated()
    func willExit()
}

