//
//  JsonHelper.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/20.
//

import Foundation

func JSONStringify<T: Codable>(_ data: T) -> String? {
    do {
        let jsonData = try JSONEncoder().encode(data)
        return String(data: jsonData, encoding: .utf8)
    } catch {
        fatalError("data JSONStringify error: \(data)")
    }
    return nil
}
