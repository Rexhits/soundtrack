//
//  FileManager.swift
//  Soundtrack_final
//
//  Created by WangRex on 12/19/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import SwiftyJSON
import AVFoundation

class STFileManager: NSObject {
    static let shared = STFileManager()
    
    func deleteDirectory(dirName: String) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent(dirName)
        do {
            try FileManager.default.removeItem(at: dataPath)
        } catch let error as NSError {
            print("Error deleting directory: \(error.localizedDescription)")
        }
    }
    
    func createJSONFile(dirName: String, filename: String, data: Data) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirPath = documentsDirectory.appendingPathComponent(dirName).appendingPathExtension("bundle")
        let filepath = dirPath.appendingPathComponent(filename).appendingPathExtension("json")
        if !FileManager.default.fileExists(atPath: dirPath.path) {
            do {
                try FileManager.default.createDirectory(at: dirPath, withIntermediateDirectories: true, attributes: nil)
                saveFile(filepath: filepath, data: data)
            } catch let error as NSError {
                print("Error creating directory: \(error.localizedDescription)")
            }
        } else {
            saveFile(filepath: filepath, data: data)
        }
        print(filepath.path)
    }
    
    private func saveFile(filepath: URL, data: Data) {
        if !FileManager.default.fileExists(atPath: filepath.path) {
            FileManager.default.createFile(atPath: filepath.path, contents: data, attributes: nil)
        } else {
            do {
                try FileManager.default.removeItem(at: filepath)
            } catch let error as NSError {
                print("Error replacing file: \(error.localizedDescription)")
            }
            FileManager.default.createFile(atPath: filepath.path, contents: data, attributes: nil)
        }

    }
    
    
    func saveCurrentBlock() {
        guard let block = PlaybackEngine.shared.loadedBlock else {return}
        let formatter = DateFormatter()
        formatter.dateFormat = "yymmddhhmmss"
        let dirName = formatter.string(from: Date())
        let fileName = "\(block.name)_musicData"
        do {
            let data = try block.asJSON.rawData()
            createJSONFile(dirName: dirName, filename: fileName, data: data)
        } catch let err as NSError {
            print("Error saving musicBlock! \(err.localizedDescription)")
        }
    }
}
