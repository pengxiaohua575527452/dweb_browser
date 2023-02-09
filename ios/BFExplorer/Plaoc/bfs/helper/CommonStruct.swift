//
//  CommonStruct.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

// 通用的泛型闭包，用于Set存储
struct GenericsClosure<C>: Hashable {
    var timestamp: Int = Date().milliStamp
    var closure: C

    static func == (lhs: GenericsClosure, rhs: GenericsClosure) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(timestamp)
    }
}

