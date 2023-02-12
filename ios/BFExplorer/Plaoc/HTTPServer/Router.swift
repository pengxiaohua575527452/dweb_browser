//
//  Router.swift
//  BFExplorer
//
//  Created by biyou on 2023/2/10.
//

import Foundation

class Router {
  
      /// The sequence of Middleware functions.
      private var middleware = [ Middleware ]()
      
      /// Add another middleware (or many) to the list
      func use(_ middleware: Middleware...) {
          self.middleware.append(contentsOf: middleware)
      }
      
      /// Request handler. Calls its middleware list
      /// in sequence until one doesn't call `next()`.
      func handle(request: IncomingMessage, response: ServerResponse, next upperNext : @escaping Next) {
          final class State {
              var stack    : ArraySlice<Middleware>
              let request  : IncomingMessage
              let response : ServerResponse
              var next     : Next?
          
              init(_ stack    : ArraySlice<Middleware>,
                   _ request  : IncomingMessage,
                   _ response : ServerResponse,
                   _ next     : @escaping Next
              ) {
                self.stack    = stack
                self.request  = request
                self.response = response
                self.next     = next
              }
          
              func step(_ args : Any...) {
                  if let middleware = stack.popFirst() {
                      middleware(request, response, self.step)
                  } else {
                      next?(); next = nil
                  }
              }
        }
        
        let state = State(middleware[middleware.indices], request, response, upperNext)
        state.step()
    }
}

extension Router {
  
    /// Register a middleware which triggers on a `GET`
    /// with a specific path prefix.
    func get(_ path: String = "", middleware: @escaping Middleware) {
        use { req, res, next in
            guard req.header.method == .GET,
                  req.header.uri.hasPrefix(path)
            else { return next() }
          
            middleware(req, res, next)
        }
    }
    
    func post(_ path: String = "", middleware: @escaping Middleware) {
        use { req, res, next in
            guard req.header.method == .POST,
                  req.header.uri.hasPrefix(path)
            else { return next() }
            
            middleware(req, res, next)
        }
    }
    
    func head(_ path: String = "", middleware: @escaping Middleware) {
        use { req, res, next in
            guard req.header.method == .HEAD,
                  req.header.uri.hasPrefix(path)
            else { return next() }
            
            middleware(req, res, next)
        }
    }
    
    func put(_ path: String = "", middleware: @escaping Middleware) {
        use { req, res, next in
            guard req.header.method == .PUT,
                  req.header.uri.hasPrefix(path)
            else { return next() }
            
            middleware(req, res, next)
        }
    }
    
    func del(_ path: String = "", middleware: @escaping Middleware) {
        use { req, res, next in
            guard req.header.method == .DELETE,
                  req.header.uri.hasPrefix(path)
            else { return next() }
            
            middleware(req, res, next)
        }
    }
    
    func patch(_ path: String = "", middleware: @escaping Middleware) {
        use { req, res, next in
            guard req.header.method == .PATCH,
                  req.header.uri.hasPrefix(path)
            else { return next() }
            
            middleware(req, res, next)
        }
    }
}
