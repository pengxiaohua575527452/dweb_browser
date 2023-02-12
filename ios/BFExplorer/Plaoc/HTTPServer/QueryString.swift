//
//  QueryString.swift
//  BFExplorer
//
//  Created by biyou on 2023/2/10.
//

import Foundation

fileprivate let paramDictKey = "bfs"

/// A middleware which parses the URL query
/// parameters. You can then access them
/// using:
///
///     req.param("id")
///
func querystring(req: IncomingMessage, res: ServerResponse, next: @escaping Next) {
    // use Foundation to parse the `?a=x`
    // parameters
    if let qi = URLComponents(string: req.header.uri)?.queryItems {
        req.userInfo[paramDictKey] =
            Dictionary<String, [URLQueryItem]>(grouping: qi, by: { $0.name })
              .mapValues { $0.compactMap({ $0.value }).joined(separator: ",") }
    }
  
  // pass on control to next middleware
  next()
}

extension IncomingMessage {
  
    /// Access query parameters, like:
    ///
    ///     let userID = req.param("id")
    ///     let token  = req.param("token")
    ///
    func param(_ id: String) -> String? {
        return (userInfo[paramDictKey] as? [ String : String ])?[id]
    }
}
