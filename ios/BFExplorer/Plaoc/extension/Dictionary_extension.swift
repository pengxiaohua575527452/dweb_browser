//
//  Dictionary_extension.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/2.
//

import Foundation

extension Dictionary {
    // 字典合并
    mutating func merge(dict: [Key: Value]) {
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}
