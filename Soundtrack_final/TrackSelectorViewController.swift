//
//  TrackSelectorViewController.swift
//  Soundtrack_final
//
//  Created by WangRex on 4/12/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import UIKit
import Material
import Charts
import AVFoundation
import ValueStepper

class TrackSelectorViewController: UICollectionViewController {
    
    
    var block: MusicBlock!
    
    
    var tracks: [ScatterChartData]!
    
    var sequenceLength: MusicTimeStamp?
    
    var selectedCell: TrackTile!
    
    var mainBlock: MusicBlock!
    
    var playBtn: FABButton!
    
    var rangeStepper: ValueStepper!
    
    var posStepper: UISlider!
    
    var clearBtn: FABButton!
    
    var saveBtn: FABButton!
    
    var fromMainBlock: Bool!
    
    var piece: Piece!
    

    
    override func viewWillAppear(_ animated: Bool) {
        getDataFromBlock()
        self.collectionView?.backgroundColor = UIColor.white.withAlphaComponent(0)
        PlaybackEngine.shared.addMusicBlock(musicBlock: block)
        PlaybackEngine.shared.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        PlaybackEngine.shared.stopSequence()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if tracks != nil {
            return tracks.count
            
        } else {
            return 0
        }
    }
    
    
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "controlHeader", for: indexPath)
        if self.rangeStepper == nil && self.posStepper == nil {
            setupSteppers(on: view)
        }
        if self.playBtn == nil && self.saveBtn == nil && self.clearBtn == nil {
            setupBtns(on: view)
        }
        
        return view
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentCell = collectionView.cellForItem(at: indexPath) as! TrackTile
        currentCell.overlay.frame.size.width = 0
        if PlaybackEngine.shared.isPlaying && selectedCell == currentCell{
            PlaybackEngine.shared.stopSequence()
        } else {
            PlaybackEngine.shared.stopSequence()
            self.sequenceLength = block.parsedTracks[indexPath.row].getSequenceLength()
            self.selectedCell = collectionView.cellForItem(at: indexPath) as! TrackTile
            let selectedTrack = block.parsedTracks[indexPath.row]
            let newBlock = MusicBlock()
            newBlock.addTrack(track: selectedTrack)
            PlaybackEngine.shared.addMusicBlock(musicBlock: newBlock)
            PlaybackEngine.shared.playSequence()
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "trackCell", for: indexPath) as! TrackTile
        cell.setTile(data: tracks[indexPath.row], name: block.parsedTracks[indexPath.row].name)
        return cell
    }
    
    
    
    func getDataFromBlock() {
        tracks = block.parsedTracks.map({ (track) -> ScatterChartData in
            let beatsPerMeasure = Double(PlaybackEngine.shared.loadedBlock!.timeSignature.beatsPerMeasure)
            let data = track.notes.map{ChartDataEntry.init(x: $0.timeStamp / beatsPerMeasure, y: Double($0.note))}
            let colors = track.notes.map({ (note) -> UIColor in
                let veolocity = note.velocity
                return UIColor(red: CGFloat(veolocity) / 128.0, green: 0, blue: 1 - (CGFloat(veolocity) / 128.0), alpha: 1)
            })
            let chartDataSet = ScatterChartDataSet(values: data)
            chartDataSet.drawValuesEnabled = false
            chartDataSet.shapeRenderer = CircleShapeRenderer()
            chartDataSet.scatterShapeSize = 5
            chartDataSet.colors = colors
            let chartData = ScatterChartData(dataSet: chartDataSet)
            return chartData
        })
        self.collectionView?.reloadData()
    }
    
}

extension TrackSelectorViewController {
    
    func playTapped(sender: FABButton) {
        self.selectedCell = nil
        if sender.isSelected {
            sender.isSelected = false
            PlaybackEngine.shared.stopSequence()
        } else {
            PlaybackEngine.shared.addMusicBlock(musicBlock: block)
            sender.isSelected = true
            let (start, end) = getSelectedRange()
            if end != 0 {
                for i in collectionView!.visibleCells {
                    let cell = i as! TrackTile
                    cell.overlay.frame.size.width = 0
                }
                PlaybackEngine.shared.setPlaybackRange(start: start, length: end)
            } else {
                self.sequenceLength = PlaybackEngine.shared.loadedBlock?.getBlockLength()
                PlaybackEngine.shared.playSequence()
            }
        }
    }
    
    func clearTapped() {
        PlaybackEngine.shared.stopSequence()
        posStepper.value = 0
        rangeStepper.value = 0
        updateSelection()
    }
    
    func rangeValueChanged(sender: ValueStepper) {
        updateSelection()
    }
    
    func posValueChanged(sender: UISlider) {
        let roundedValue = round(sender.value)
        sender.value = roundedValue
        if rangeStepper.value == 0 {
            rangeStepper.value = 1
        }
        updateSelection()
    }
    
    func saveTapped() {
        let (start, length) = getSelectedRange()
        
        if length == 0 {
            let clip = Clip(length: block.getBlockLength(), data: block.getSequenceData()! as NSData, fromMainBlock: self.fromMainBlock)
            clip.timeSignature = "\(block.timeSignature.lengthPerBeat)/\(block.timeSignature.beatsPerMeasure)"
            clip.tempo = Int16(block.tempo)
            clip.key = Int16(block.key)
            clip.inPiece = piece
        } else {
            if fromMainBlock {
                let newBlock = block.selectRange(start: start, length: length)
                let clip = Clip(length: newBlock.getBlockLength(), data: newBlock.getSequenceData()! as NSData, fromMainBlock: self.fromMainBlock)
                clip.timeSignature = "\(block.timeSignature.lengthPerBeat)/\(block.timeSignature.beatsPerMeasure)"
                clip.tempo = Int16(block.tempo)
                clip.key = Int16(block.key)
                clip.inPiece = piece
                clip.userComposed = false
                for _ in newBlock.parsedTracks {
                    let trackData = TrackData(volume: 1, pan: 0)
                    trackData.inClip = clip
                }
            } else {
                let cuttedBlock = block.selectRange(start: start, length: length)
                let main = self.mainBlock!
                var tracks = [Track].init(repeating: Track(), count: main.parsedTracks.count)
                for i in cuttedBlock.parsedTracks.enumerated() {
                    for var n in i.element.notes {
//                        n.timeStamp -= start
                        let note = MusicBlock.NoteOnTrack(noteEvent: n, onTrack: i.offset, trackType: i.element.sequenceType)
                        let mappedTrack = main.trackMapping(input: note)
                        if mappedTrack != nil {
                            tracks[mappedTrack!].addNote(note: n)
                        }
                        
                    }
                }
                let newBlock = MusicBlock()
                newBlock.addTracks(tracks: tracks)
                let clip = Clip(length: newBlock.getBlockLength(), data: newBlock.getSequenceData()! as NSData, fromMainBlock: self.fromMainBlock)
                clip.timeSignature = "\(block.timeSignature.lengthPerBeat)/\(block.timeSignature.beatsPerMeasure)"
                clip.tempo = Int16(block.tempo)
                clip.key = Int16(block.key)
                clip.inPiece = piece
                clip.userComposed = false
                for _ in newBlock.parsedTracks {
                    let trackData = TrackData(volume: 1, pan: 0)
                    trackData.inClip = clip
                }
            }
            
        }
        appDelegate.saveContext()
        _ = navigationController?.popViewController(animated: true)
    }
    
    func updateSelection() {
        let startPoint = Double(self.posStepper.value)
        let length = self.rangeStepper.value
        for i in collectionView!.visibleCells {
            let cell = i as! TrackTile
            let maxLength = cell.chart.xAxis.axisMaximum
            let lengthPerStep = maxLength * Double(self.block.timeSignature.beatsPerMeasure)
            cell.overlay.frame.size.width = CGFloat(length / maxLength) * cell.chart.frame.size.width
            cell.overlay.frame.origin.x = CGFloat(startPoint / lengthPerStep) * cell.chart.frame.size.width
//            print(cell.overlay.frame.origin.x)
        }
    }
    
    func getSelectedRange() -> (AVMusicTimeStamp, AVMusicTimeStamp) {
        let startPoint = Double(self.posStepper.value)
        let length = self.rangeStepper.value
        return (startPoint, (length * Double(block.timeSignature.beatsPerMeasure)))
    }
    
    
    func setupBtns(on: UIView) {
        playBtn = FABButton(image: Icon.cm.play, tintColor: .white)
        playBtn.setImage(Icon.cm.pause, for: .selected)
        playBtn.backgroundColor = UIColor.hexStringToUIColor(hex: "#46b9be")
        playBtn.pulseColor = UIColor.white
        let selector = #selector(playTapped(sender:))
        playBtn.addTarget(self, action: selector, for: .touchUpInside)
        on.addSubview(playBtn)
        
        let chartFrame = collectionView!.layoutAttributesForItem(at: IndexPath(row: 0, section: 0))!.frame
        let x = collectionView!.convert(chartFrame.origin, to: on)
        on.layout(playBtn).topLeft(top: 25, left: x.x).size(CGSize(width: 50, height: 50))
        clearBtn = FABButton(image: Icon.cm.clear, tintColor: .white)
        clearBtn.backgroundColor = UIColor.hexStringToUIColor(hex: "#218197")
        clearBtn.pulseColor = UIColor.white
        clearBtn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        on.addSubview(clearBtn)
        on.layout(clearBtn).topLeft(top: 25, left: 2 * x.x + 33).size(CGSize(width: 50, height: 50))
        
        saveBtn = FABButton(image: Icon.cm.pen, tintColor: .white)
        saveBtn.backgroundColor = UIColor.hexStringToUIColor(hex: "#577657")
        saveBtn.pulseColor = .white
        saveBtn.addTarget(self, action:  #selector(saveTapped), for: .touchUpInside)
        on.addSubview(saveBtn)
        on.layout(saveBtn).topLeft(top: 25, left: 3 * x.x + 66).size(CGSize(width: 50, height: 50))
    }
    
    func setupSteppers(on: UIView) {
        let height = on.height
        rangeStepper = ValueStepper()
        rangeStepper.tintColor = UIColor.white
        rangeStepper.minimumValue = 0
        rangeStepper.maximumValue = block.getBlockLength()
        rangeStepper.stepValue = 1
        let rangeSelector = #selector(rangeValueChanged(sender:))
        rangeStepper.addTarget(self, action: rangeSelector, for: .valueChanged)
        on.addSubview(rangeStepper)
        on.layout(rangeStepper).center(offsetX: 0, offsetY: 30)
        let chartFrame = collectionView!.layoutAttributesForItem(at: IndexPath(row: 0, section: 0))!.frame
        let x = collectionView!.convert(chartFrame.origin, to: on)
        posStepper = UISlider(frame: CGRect(x: x.x, y: height - 30, width: chartFrame.width, height: 30))
        posStepper.tintColor = UIColor.orange
        posStepper.minimumValue = 0
        posStepper.maximumValue = Float(block.getBlockLength())
        posStepper.thumbTintColor = UIColor.hexStringToUIColor(hex: "#aaaaaa")
        posStepper.setMaximumTrackImage(UIImage(), for: .normal)
        posStepper.setMinimumTrackImage(UIImage(), for: .normal)
        let posSelector = #selector(posValueChanged(sender:))
        posStepper.addTarget(self, action: posSelector, for: .valueChanged)
        on.addSubview(posStepper)
    }

}

extension TrackSelectorViewController: PlaybackEngineDelegate {
    func updateTime(currentTime: AVMusicTimeStamp) {
        guard PlaybackEngine.shared.isPlaying else {
            return
        }
        DispatchQueue.main.async {
            if self.selectedCell == nil {
                for i in self.collectionView!.visibleCells {
                    let cell = i as! TrackTile
                    let length = cell.chart.xAxis.axisMaximum * Double(self.block.timeSignature.beatsPerMeasure)
                    cell.overlay.frame.size.width = CGFloat(currentTime / length) * cell.chart.frame.size.width - cell.overlay.frame.origin.x
                }
            } else {
                let length = self.selectedCell.chart.xAxis.axisMaximum * Double(self.block.timeSignature.beatsPerMeasure)
                self.selectedCell.overlay.frame.size.width = CGFloat(currentTime / length) * self.selectedCell.frame.size.width
            }
        }
        
    }
    
    func didLoadBlock(block: MusicBlock) {
        //
    }
    func didFinishLoop() {
        //
    }
    func didStartLoop() {
        //
    }
    func didStartPlaying() {
        //
        DispatchQueue.main.async {
            self.playBtn.isSelected = true
        }
    }
    func didFinishPlaying() {
        //
        DispatchQueue.main.async {
            for i in self.collectionView!.visibleCells {
                let cell = i as! TrackTile
                cell.overlay.frame.size.width = 0
            }
            self.playBtn.isSelected = false
            self.updateSelection()
        }
    }
}

extension TrackSelectorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

class TrackTile: UICollectionViewCell {
    var overlay: UIView!
    var chart: ChartView!
    override func layoutSubviews() {
        overlay = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: self.frame.size.height))
        overlay.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        self.contentView.addSubview(overlay)
        overlay.layoutIfNeeded()
    }
    func setTile(data: ScatterChartData, name: String) {
        chart = ChartView(frame: self.bounds)
        chart.data = data
        //        chart.frame = cell.contentView.bounds
        self.backgroundView = chart
        chart.layoutIfNeeded()
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let text = UILabel()
        text.text = name
        text.font = text.font.withSize(12)
        text.textColor = UIColor.white.withAlphaComponent(0.8)
        chart.addSubview(text)
        chart.layout(text).topLeft()
    }
    
}

class ChartView: ScatterChartView {
    
    override func layoutSubviews() {
        self.chartDescription?.text = ""
        self.isUserInteractionEnabled = false
        self.highlighter = nil
        self.rightAxis.enabled = false
        //        self.xAxis.drawGridLinesEnabled = false
        //        self.drawGridBackgroundEnabled = false
        
        //        self.xAxis.drawLabelsEnabled = false
        self.xAxis.drawAxisLineEnabled = false
        self.xAxis.labelPosition = .bottom
        self.xAxis.labelTextColor = .white
        //        self.drawBordersEnabled = false
        //            self.leftAxis.drawGridLinesEnabled = false
        self.leftAxis.drawAxisLineEnabled = false
        self.leftAxis.drawLabelsEnabled = false
        self.minOffset = 0
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
