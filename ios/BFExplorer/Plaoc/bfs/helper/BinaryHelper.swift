//
//  BinaryHelper.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/16.
//

import Foundation
import Vapor


public func isBinary(data: Any) -> Bool {
    data is ByteBuffer
}

public func binaryToU8a(binary: ByteBuffer) -> [UInt8] {
    var buffer = binary
    return Array(String(data: buffer.readData(length: buffer.readableBytes)!, encoding: .utf8)!.utf8)
}

public func u8aConcat(binaryList: [[UInt8]]) -> [UInt8] {
    var result: [UInt8] = []
    for binary in binaryList {
        result += binary
    }
    
    return result
}
