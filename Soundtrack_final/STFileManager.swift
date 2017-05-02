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
        let dirPath = documentsDirectory.appendingPathComponent(dirName)
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
    
    func createMidiFile(dirName: String, filename: String, data: Data) -> String {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirPath = documentsDirectory.appendingPathComponent(dirName)
        let filepath = dirPath.appendingPathComponent(filename).appendingPathExtension("mid")
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
        return filepath.path
    }
    
    func createAUPreset(block: MusicBlock) {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirPath = documentsDirectory.appendingPathComponent(block.name)
        for i in block.parsedTracks {
            let subdir = dirPath.appendingPathComponent("instStatus")
            createDir(atPath: subdir)
            let filepath = subdir.appendingPathComponent("track_\(i.trackIndex!)").appendingPathExtension("aupreset")
            if FileManager.default.fileExists(atPath: filepath.path) {
                try! FileManager.default.removeItem(at: filepath)
                print("Deleted")
            }
            let instStatus = i.instrument!.auAudioUnit.fullState! as NSDictionary
            instStatus.write(to: filepath, atomically: true)
            for t in i.effects.enumerated() {
                let subdir = dirPath.appendingPathComponent("fxStatus")
                createDir(atPath: subdir)
                let filepath = subdir.appendingPathComponent("track_\(i.trackIndex!)_\(t.offset)").appendingPathExtension("aupreset")
                if FileManager.default.fileExists(atPath: filepath.path) {
                    try! FileManager.default.removeItem(at: filepath)
                    print("Deleted")
                }
                let fxStatus = t.element.auAudioUnit.fullState! as NSDictionary
                fxStatus.write(to: filepath, atomically: true)
            }
        }
    }
    
    func createDir(atPath: URL) {
        if !FileManager.default.fileExists(atPath: atPath.path) {
            do {
                try FileManager.default.createDirectory(at: atPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
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
    
    func getPresetPath() -> ([String]?, [String]?) {
        guard let block = PlaybackEngine.shared.loadedBlock else {return (nil,nil)}
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirPath = documentsDirectory.appendingPathComponent(block.name)
        let instDir = dirPath.appendingPathComponent("instStatus")
        let fxDir = dirPath.appendingPathComponent("fxStatus")
        if FileManager.default.fileExists(atPath: dirPath.path) {
            return (FileManager.default.listFiles(path: instDir.path), FileManager.default.listFiles(path: fxDir.path))
        } else {
            return (nil, nil)
        }
    }
    
    func saveCurrentBlock(block: MusicBlock) {
        let dirName = block.name
        let fileName = block.name
        let json = block.asJSON
        createAUPreset(block: block)
        do {
            let data = try json.rawData()
            createJSONFile(dirName: dirName, filename: fileName, data: data)
        } catch let err as NSError {
            print("Error saving musicBlock! \(err.localizedDescription)")
        }
    }
    
    func uploadCurrentBlock(block: MusicBlock, billboard:String, completion: @escaping (JSONPackage?, Error?, Int?)->Void) {
        if block.url == nil {
            ServerCommunicator.shared.uploadBlock(block: block, billboard: billboard, completion: completion)
        } else {
            ServerCommunicator.shared.editBlock(block: block, completion: completion)
        }
        
    }
    
    func getTempDir() -> URL{
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirPath = documentsDirectory.appendingPathComponent("temp")
        createDir(atPath: dirPath)
        return dirPath
    }
    
    func createAUSamplerPresetFolder() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirPath = documentsDirectory.appendingPathComponent("AUSampler")
        createDir(atPath: dirPath)
        let files = Bundle.main.urls(forResourcesWithExtension: "aupreset", subdirectory: nil)
        if let aupresets = files {
            for i in aupresets {
                do {
                    
                    try FileManager.default.moveItem(at: i, to: dirPath.appendingPathComponent(i.lastPathComponent))
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func getAUSapmlerPresets() -> [String] {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dirPath = documentsDirectory.appendingPathComponent("AUSampler")
        return FileManager.default.listFiles(path: dirPath.path)
    }
    
    func clearInbox() {
        let dir = getURLInDocumentDirectoryWithFilename(filename: "Inbox")
        let files = FileManager.default.listFiles(path: dir.path)
        for i in files {
            try! FileManager.default.removeItem(atPath: i)
        }
    }
    
    func getBounceDir() -> URL {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory = path[0] as String
        let fullPath = URL(fileURLWithPath: "\(documentDirectory)/bounce")
        createDir(atPath: fullPath)
        return fullPath
    }
    
    func deleteFile(atURL: URL) {
        do {
            try FileManager.default.removeItem(at: atURL)
        } catch let error as NSError {
            print("Error deleting directory: \(error.localizedDescription)")
        }
    }
    
    func emptyTempFoler() {
        do {
            try FileManager.default.removeItem(at: getTempDir())
        } catch {
            print(error.localizedDescription)
        }
    }
}
