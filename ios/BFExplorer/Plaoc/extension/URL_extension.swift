//
//  URL_extension.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/2.
//

import Foundation

extension URL {
    var urlParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
        let queryItems = components.queryItems else { return nil }
        return queryItems.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        }
    }
}
