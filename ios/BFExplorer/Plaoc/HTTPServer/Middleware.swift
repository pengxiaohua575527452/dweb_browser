//
//  Middleware.swift
//  BFExplorer
//
//  Created by biyou on 2023/2/10.
//

import Foundation

typealias Next = ( Any... ) -> Void

typealias Middleware = ( IncomingMessage, ServerResponse, @escaping Next ) -> Void

