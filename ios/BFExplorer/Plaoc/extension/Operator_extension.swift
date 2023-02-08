//
//  Operator_extension.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

// 前缀 ++
prefix operator ++
prefix func ++(x: inout Int) -> Int {
    let current = x
    x += 1
    return current
}

// 后缀 ++
postfix operator +
postfix func ++(x: inout Int) -> Int {
    let current = x
    x += 1
    return current
}
