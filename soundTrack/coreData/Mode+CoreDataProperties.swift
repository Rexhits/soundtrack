//
//  Mode+CoreDataProperties.swift
//  soundTrack
//
//  Created by WangRex on 8/1/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation
import CoreData

extension Mode {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Mode> {
        return NSFetchRequest<Mode>(entityName: "Mode");
    }

    @NSManaged public var category: String?
    @NSManaged public var name: String?
    @NSManaged public var subCategory: String?
    @NSManaged public var scale: Scale?

}
