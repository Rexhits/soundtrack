//
//  GlobalFunctions.swift
//  soundTrack
//
//  Created by WangRex on 7/19/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class GlobalFunctions {
    static func getURLInDocumentDirectoryWithFilename (filename: String) -> NSURL {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentDirectory = path[0] as String
        let fullpath = "\(documentDirectory)/\(filename)"
        return NSURL(fileURLWithPath: fullpath)
    }
    static let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    
}

class DataManager {
    private static func getContext() -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    static func newMode(name: String, category: String, subCategory: String?, upScale: [Int], downScale:[Int]) {
        let context = DataManager.getContext()
        let scaleEntity = NSEntityDescription.entity(forEntityName: "Scale", in: context)
        let newScale = NSManagedObject(entity: scaleEntity!, insertInto: context)
        let modeEntity = NSEntityDescription.entity(forEntityName: "Mode", in: context)
        let newMode = NSManagedObject(entity: modeEntity!, insertInto: context)
        newMode.setValue(name, forKey: "name")
        newMode.setValue(category, forKey: "category")
        newMode.setValue(subCategory, forKey: "subCategory")
        newScale.setValue(upScale, forKey: "upgoing")
        newScale.setValue(downScale, forKey: "downgoing")
        newMode.setValue(newScale, forKey: "scale")
        newScale.setValue(newMode, forKey: "modeBelongsTo")
        do {
            try context.save()
            print("saved")
        } catch let err as NSError {
            print("Could not save \(err), \(err.userInfo)")
        }
    }
    
    
    static func preloadData() {
        let directoryURL = NSPersistentContainer.defaultDirectoryURL()
        let fileURL = directoryURL.appendingPathComponent("MusicTheory.sqlite")
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            print("file is not there")
            let sourceSqliteURLs = [Bundle.main.url(forResource: "MusicTheory", withExtension: "sqlite")!, Bundle.main.url(forResource: "MusicTheory", withExtension: "sqlite-wal")!, Bundle.main.url(forResource: "MusicTheory", withExtension: "sqlite-shm")!]
            let destSqliteURLs = [directoryURL.appendingPathComponent("MusicTheory.sqlite"), directoryURL.appendingPathComponent("MusicTheory.sqlite-wal"), directoryURL.appendingPathComponent("MusicTheory.sqlite-shm")]
            for i in 0 ..< sourceSqliteURLs.count {
                do {
                    try FileManager.default.copyItem(at: sourceSqliteURLs[i], to: destSqliteURLs[i])
                } catch let err as NSError {
                    print("error copying database! \(err)")
                }
                
            }
        } else {
            print("file is there")
        }
    }
    
    static func getAllModes() -> [Mode] {
        //create a fetch request, telling it about the entity
        let fetchRequest: NSFetchRequest<Mode> = Mode.fetchRequest()
        let context = DataManager.getContext()
        do {
            //go get the results
            let searchResults = try context.fetch(fetchRequest)
            
            //I like to check the size of the returned results!
            print ("num of results = \(searchResults.count)")
            return searchResults as [Mode]
        } catch {
            print("Error with request: \(error)")
            return []
        }
    }

    static func getModesbyCategory(category: String) -> [Mode] {
        let fetchRequest: NSFetchRequest<Mode> = Mode.fetchRequest()
        let context = DataManager.getContext()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        do {
            let searchResults = try context.fetch(fetchRequest)
            return searchResults as [Mode]
        } catch {
            print("Error with request: \(error)")
            return []
        }
    }
    
    
    static func getModesbyScale(scale: [Int]) -> [Mode] {
        let fetchRequest: NSFetchRequest<Scale> = Scale.fetchRequest()
        var modes = [Mode]()
        let context = DataManager.getContext()
        let upgoingPredicates = NSPredicate(format: "upgoing == %@", scale)
        let downgoingPredicates = NSPredicate(format: "downgoing == %@", scale)
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [upgoingPredicates, downgoingPredicates])
        do {
            let searchResults = try context.fetch(fetchRequest)
            let scales = searchResults as [Scale]
            for i in scales {
                modes.append(i.modeBelongsTo!)
            }
        } catch {
            print("Error with request: \(error)")
        }
        return modes
    }
    
    static func getMode(category: String, subCategory: String?, name: String) -> [Mode] {
        let fetchRequest: NSFetchRequest<Mode> = Mode.fetchRequest()
        let context = DataManager.getContext()
        let categoryPredicate = NSPredicate(format: "category == %@", category)
        let namePredicate = NSPredicate(format: "name == %@", name)
        if subCategory != nil {
            let subCategoryPredicate = NSPredicate(format: "subCategory == %@", subCategory!)
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, subCategoryPredicate, namePredicate])
        } else {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, namePredicate])
        }
        do {
            let searchResults = try context.fetch(fetchRequest)
            return searchResults as [Mode]
        } catch {
            print("Error with request: \(error)")
            return []
        }
    }
}

extension Float {
    static func randomPercent() -> Float {
        return Float(arc4random() % 1000) / 10.0;
    }
}

extension Int {
    static func random(input:Int) -> Int {
        return Int(arc4random_uniform(UInt32(input)))
    }
    static func randomIndex(probabilities: [Double]) -> Int {
        
        // Sum of all probabilities (so that we don't have to require that the sum is 1.0):
        let sum = probabilities.reduce(0, +)
        // Random number in the range 0.0 <= rnd < sum :
        let rnd = sum * Double(arc4random_uniform(UInt32.max)) / Double(UInt32.max)
        // Find the first interval of accumulated probabilities into which `rnd` falls:
        var accum = 0.0
        for (i, p) in probabilities.enumerated() {
            accum += p
            if rnd < accum {
                return i
            }
        }
        // This point might be reached due to floating point inaccuracies:
        return (probabilities.count - 1)
    }
}

func ~=<T: Equatable>(lhs: [T], rhs: [T]) -> Bool {
    return lhs == rhs
}


