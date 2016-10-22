//
//  Global.swift
//  Soundtrack_final
//
//  Created by WangRex on 10/6/16.
//  Copyright © 2016 WangRex. All rights reserved.
//

import Foundation

var token = NSString()

let n: UInt8 = 0

func iteratorForTuple(tuple: Any) -> AnyIterator<Any> {
    return AnyIterator(Mirror(reflecting: tuple).children.lazy.map { $0.value }.makeIterator())
}
