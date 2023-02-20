//
//  IpcHeaders.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/16.
//

import Foundation
import Vapor


struct IpcHeaders: Codable {
    typealias Headers = [String:String]

    var headers: Headers

    init(_ headers: Headers) {
        self.headers = headers
    }
    
    init(_ headers: HTTPHeaders) {
        self.headers = headers.reduce(into: [:]) { $0[$1.0] = $1.1 }
    }

    init(from decoder: Decoder) throws {
        self.headers = try Headers.init(from: decoder)
    }

    enum CodingKeys: String, CodingKey {
        case headers
    }

    func encode(to encoder: Encoder) throws {
        try self.headers.encode(to: encoder)
    }
    
    mutating func set(key: String, value: String) {
        if headers[key.lowercased()] == nil {
            headers[key.lowercased()] = value
        }
    }
    
    func get(key: String) -> String? {
        return headers[key.lowercased()]
    }
    
    func getOrDefault(key: String, defaultValue: String) -> String {
        return get(key: key) ?? defaultValue
    }
    
    func has(key: String) -> Bool {
        return headers[key.lowercased()] != nil
    }
    
    mutating func delete(key: String) {
        headers.removeValue(forKey: key.lowercased())
    }
    
    func toHTTPHeaders() -> HTTPHeaders {
        return HTTPHeaders(headers.map{$0})
    }
    
    func toDic() -> Headers {
        return headers
    }
    
    func forEach(_ fn: (String, String) -> Void) {
        headers.forEach(fn)
    }
}



