//
//  TrackTypeClassifier.swift
//  Soundtrack_final
//
//  Created by WangRex on 1/24/17.
//  Copyright © 2017 WangRex. All rights reserved.
//

import AIToolbox
import Foundation


class TrackTypeClassifier {
    static let shared = TrackTypeClassifier()
    var svm = SVMModel(problemType: .c_SVM_Classification, kernelSettings: KernelParameters(type: .radialBasisFunction, degree: 0, gamma: 0.5, coef0: 0.0))
    let data = DataSet(dataType: .realAndClass, inputDimension: 4, outputDimension: 1)
    
    func addDataPoint(input: [Double], output: Int) {
        do {
            try data.addDataPoint(input: input, dataClass: output)
        } catch {
            print("Invalid data set created \(error)")
        }
    }
    
    func train() {
        svm.train(data)
    }
    
    func predict(input: [Double]) -> Double {
        return svm.predictOne(input)
    }
    
    func saveToFile() {
        let path = getURLInDocumentDirectoryWithFilename(filename: "trackClassifier.plist")
        print(path)
        do {
            try svm.saveToFile(path.path)
        } catch {
            print("Error saving SVM file \(error)")
        }
    }
    
    func readFromFIle() {
        let path = getURLInDocumentDirectoryWithFilename(filename: "trackClassifier.plist")
        let readSVM = SVMModel(loadFromFile: path.path)
        if let readSVM = readSVM {
            self.svm = readSVM
        }
    }
    
}
