//
//  taskManager.swift
//  SoundTrack
//
//  Created by WangRex on 3/29/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation

class TaskManager: NSObject {
    static let sharedInstance = TaskManager()
    
    var name = [String]()
    var location = [String]()
    var difficulty = [String]()
    var latitude = [Double]()
    var longitude = [Double]()
    var selectedTask: Int = 0
    // not implemented yet
    var collected = [Bool] ()
    var completion = [Float] ()
    
    func addNew(name: String, location: String, difficulty: String, latitude: [Double], longitude: [Double]) {
            self.name.append(name)
            self.location.append(location)
            self.difficulty.append(difficulty)
        for i in 0 ..< latitude.count {
            self.latitude.append(latitude[i])
            self.longitude.append(longitude[i])
        }
    }
}