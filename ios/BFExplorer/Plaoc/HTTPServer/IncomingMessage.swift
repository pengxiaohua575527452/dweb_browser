//
//  IncomingMessage.swift
//  BFExplorer
//
//  Created by biyou on 2023/2/10.
//

import Foundation
import NIOHTTP1

class IncomingMessage {
  
    public let header   : HTTPRequestHead
    public var userInfo = [ String : Any ]()
    public var body     : Any?
  
    init(header: HTTPRequestHead) {
        self.header = header
    }
    
    func setBody(body: Any) {
        self.body = body
    }
}
