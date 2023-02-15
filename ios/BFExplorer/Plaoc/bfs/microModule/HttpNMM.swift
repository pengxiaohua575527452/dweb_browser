//
//  HttpsNMM.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation
import Vapor

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

struct ReqMathcher: Hashable {
    let pathname: String
    let matchMode: MatchMode
    let method: HTTPMethod
    
    static func ==(lhs: ReqMathcher, rhs: ReqMathcher) -> Bool {
        return lhs.pathname == rhs.pathname
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(pathname)
    }
}

struct Router: Hashable {
    let routes: [ReqMathcher]
    var streamIpc: NativeIpc
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(streamIpc)
    }
    
    static func == (lhs: Router, rhs: Router) -> Bool {
        return lhs.streamIpc == rhs.streamIpc
    }
}

func isMatchReq(matcher: ReqMathcher, pathname: String, method: HTTPMethod) -> Bool {
    return (
        (matcher.method ?? HTTPMethod.GET) == method &&
        (matcher.matchMode == MatchMode.full
         ? pathname == matcher.pathname
         : matcher.matchMode == MatchMode.prefix
         ? pathname.hasPrefix(matcher.pathname)
         : false)
    )
}

class PortListener {
    let ipc: NativeIpc?
    let host: String
    let origin: String
    
    init(ipc: NativeIpc?, host: String, origin: String) {
        self.ipc = ipc
        self.host = host
        self.origin = origin
    }
    
    private var _routers: Set<Router> = []
    func addRouter(router: Router) -> () -> Void {
        _routers.insert(router)
        
        return {
            self._routers.remove(router)
            return
        }
    }
    
    private func _isBindMatchReq(pathname: String, method: HTTPMethod) -> (Router, ReqMathcher)? {
        for bind in _routers {
            for pathMatcher in bind.routes {
                if isMatchReq(matcher: pathMatcher, pathname: pathname, method: method) {
                    return (bind, pathMatcher)
                }
            }
        }
        
        return nil
    }
    
//    func hookHttpRequest(req: )
}

struct GetHostOptions {
    var ipc: NativeIpc?
    var port: Int?
    var subdomain: String?
}

class HttpNMM: NativeMicroModule {
    private var _tokenMap: [/* token */String:PortListener] = [:]
    private var _gatewayMap: [/* host */String:PortListener] = [:]

    convenience init() {
        self.init(mmid: "http.sys.dweb")
    }
    
    let port = 22605
    override func _bootstrap() -> Any {
        Task(priority: .background) {
            do {
                HttpServer.createServer(port)
                let app = HttpServer.app
                
                app.get(["\(self.mmid)", "listen"]) { req in
                    
                    guard let port = req.query[Int.self, at: "port"],
                          let subdomain = req.query[String.self, at: "subdomain"],
                          let mmid = req.query[String.self, at: "mmid"]
                    else {
                        return ""
                    }
                    
                    let (_, origin) = self.listen(hostOptions: HostParam(port: port, mmid: mmid, subdomain: subdomain))
                    print(origin)

                    return origin
                }
                
                app.get(["\(self.mmid)", "unlisten"]) { req in
                    guard let port = req.query[Int.self, at: "port"],
                          let subdomain = req.query[String.self, at: "subdomain"],
                          let mmid = req.query[String.self, at: "mmid"]
                    else {
                        return false
                    }
                    
                    return self.unlisten(hostOptions: HostParam(port: port, mmid: mmid, subdomain: subdomain))
                }
                
                app.get("") { req in
                    print(req)
                    return ""
                }
                
                try app.start()
            } catch {
                fatalError("http server start error: \(error)")
            }
        }
    }
    
    private func listen(hostOptions: HostParam) -> (String, String) {
        let host = self.getHost(hostOption: HostParam(port: hostOptions.port, mmid: hostOptions.mmid, subdomain: hostOptions.subdomain))
        let origin = "\(customProtocol)://\(host)"
        
        // TODO: 未完成base64加密
        let token = "dweb-browser-random-token"
        
        self._gatewayMap[host] = PortListener(ipc: nil, host: host, origin: origin)
        return (token, origin)
    }
    
    private func unlisten(hostOptions: HostParam) -> Bool {
        let host = self.getHost(hostOption: HostParam(port: hostOptions.port, mmid: hostOptions.mmid, subdomain: hostOptions.subdomain))
        
        let gateway = self._gatewayMap[host]
        
        if gateway == nil {
            return false
        }
        
        self._tokenMap.removeValue(forKey: host)
        self._gatewayMap.removeValue(forKey: host)
        
        return true
    }
    
    struct HostParam {
        var port: Int
        var mmid: MMID
        var subdomain: String
    }
    
    func parserHostParam(host: String) -> HostParam? {
        if host.hasSuffix("localhost:\(self.port)") {
            let host = host.replacingOccurrences(of: "localhost\(self.port)", with: "")
            let hostArr = host.split(separator: ".")
            
            if hostArr.count >= 3 {
                let dwebPart = hostArr.last
                
                if !dwebPart!.hasPrefix("dweb") {
                    return nil
                }
                guard let port = Int(dwebPart!.replacingOccurrences(of: "dweb-", with: "")) else {
                    return nil
                }
                let mmid = hostArr[hostArr.count-3...hostArr.count-1].joined(separator: ".") + ".dweb"
                let subdomain = hostArr[0...hostArr.count-3].joined(separator: ".")
                
                return HostParam(port: port, mmid: mmid, subdomain: subdomain)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func getHost(hostOption: HostParam) -> String {
        return "\(hostOption.subdomain).\(hostOption.mmid)-\(hostOption.port).\(HttpServer.address!)"
    }
    
    deinit {
        HttpServer.app.shutdown()
    }
}

