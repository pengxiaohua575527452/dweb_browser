//
//  HTTPServerManager.swift
//  BFExplorer
//
//  Created by ui03 on 2023/2/9.
//

import UIKit
import CocoaHTTPServer

class HTTPServerManager: NSObject {

    static let shared = HTTPServerManager()
    private var localHttpServer: HTTPServer?
    private(set) var port: String = ""
    
    
    override init() {
        super.init()
        localHttpServer = HTTPServer()
        localHttpServer?.setType("_http.tcp")
    }
    //开启服务
    func startServer(path: String) {
        localHttpServer?.setDocumentRoot(path)
        do {
            try localHttpServer?.start()
            port = String(format: "%d", localHttpServer!.listeningPort())
        } catch {
            print("Error starting HTTP Server: \(error)")
        }
        print("http://localhost:\(port)")
    }
    //停止服务
    func stopServer(path: String) {
        localHttpServer?.stop()
    }
    
    
}
