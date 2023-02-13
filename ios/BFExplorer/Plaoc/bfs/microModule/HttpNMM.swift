//
//  HttpsNMM.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation


let customProtocol = "http"

enum REQUEST_METHOD: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case options = "OPTIONS"
}

struct HttpRequestInfo {
    var http_req_id: Int
    var url: String
    var method: REQUEST_METHOD
    var rawHeaders: [String]
}

struct HttpResponseInfo {
    var http_req_id: Int
    var statusCode: Int
    var headers: [String:String]
    // string | Uint8Array | ReadableStream<Uint8Array | string>
    var body: Any
}

class HttpListener {
    var host: String
    var port: Int
    
    struct Streams {
        let input: InputStream
        let output: OutputStream
    }
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
    }
    
    lazy var origin: String = "\(customProtocol)://\(host)"
    
    var _http_req_id_acc = 0
    func allocHttpReqId() -> Int {
        return _http_req_id_acc++
    }
    
//    func hookHttpRequest()
}

class HttpNMM: NativeMicroModule {
    
    override func _bootstrap() -> Any {
        return true
    }
    
    convenience init() {
        self.init(mmid: "http.sys.dweb")
        
        Routers["/listen"] = { args in
            
        }
    }
    
//    private func _getHost(port: Int, ipc: Ipc) {
//        return "\(ipc.remote.mmid).\(port).localhost:\(this._local_port)";
//    }
    
    private func listen(port: Int) {
        
    }
}

