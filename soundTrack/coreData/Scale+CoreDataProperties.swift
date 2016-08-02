//
//  Scale+CoreDataProperties.swift
//  soundTrack
//
//  Created by WangRex on 8/1/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import CoreData

extension Scale {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Scale> {
        return NSFetchRequest<Scale>(entityName: "Scale");
    }

    @NSManaged public var downgoing: NSObject?
    @NSManaged public var upgoing: NSObject?
    @NSManaged public var modeBelongsTo: Mode?

}
