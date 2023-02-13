//
//  HttpServer.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/13.
//

import Foundation
import Vapor

class HttpServer: ObservableObject {
    func createServer(_ port: Int, _ host: String = "localhost") -> Application {
        let app = Application(.development, .createNew)
        
        configure(app, host: host, port: port)
        
        return app
    }
    
    func configure(_ app: Application, host: String, port: Int) {
          app.http.server.configuration.hostname = host
          app.http.server.configuration.port = port

          app.routes.defaultMaxBodySize = "50MB"
    }
}
