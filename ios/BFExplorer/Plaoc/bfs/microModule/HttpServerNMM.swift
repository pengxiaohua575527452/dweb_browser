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

class HttpServerNMM: NativeMicroModule {
    var tokenMap: [/* token */String:PortListener] = [:]
    var gatewayMap: [/* host */String:PortListener] = [:]

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
                
                app.middleware.use(RequestMiddleware())
                
                try app.start()
            } catch {
                fatalError("http server start error: \(error)")
            }
        }
    }
    
    /// 拦截所有请求
    struct RequestMiddleware: Middleware {
        func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
            var host = "*"
            
            if request.headers.contains(name: "User-Agent") {
                host = request.headers.first(name: "User-Agent")!
                
                print("RequestMiddleware host: \(host)")
            }
            
            // 网关未找到判断
            let gateway = DnsNMM.shared.httpServerNMM.gatewayMap[host]
            if gateway == nil && !request.url.path.hasPrefix("/http.sys.dweb") {
                let promise = request.eventLoop.makePromise(of: Response.self)
                promise.succeed(
                    DnsNMM.shared.httpServerNMM.defaultErrorResponse(
                        req: request,
                        statusCode: .badGateway,
                        errorMessage: "Bad Gateway",
                        detailMessage: "作为网关或者代理工作的服务器尝试执行请求时，从远程服务器接收到了一个无效的响应"
                    )
                )

                return promise.futureResult
            }
            
            // 未找到路由判断
            let app = HttpServer.app
            let routes = app.routes.all
            if !routes.contains(where: { route in
                let routePath = "/" + route.path.map { "\($0)" }.joined(separator: "/")
                if routePath == request.url.path && route.method == request.method {
                    return true
                } else {
                    return false
                }
            }) {
                let promise = request.eventLoop.makePromise(of: Response.self)
                promise.succeed(
                    DnsNMM.shared.httpServerNMM.defaultErrorResponse(
                        req: request,
                        statusCode: .notFound,
                        errorMessage: "not found",
                        detailMessage: "未找到"
                    )
                )
                
                return promise.futureResult
            }
            
            
            return next.respond(to: request)
        }
    }
    
    /// 网关错误，默认返回
    func defaultErrorResponse(req: Request, statusCode: HTTPResponseStatus, errorMessage: String, detailMessage: String) -> Response {
//            let headers = req.headers.reduce(into: [:]) { $0[$1.0] = $1.1 }
        var headerJsonString = ""
        _ = req.headers.map { item in
            headerJsonString += "\(item.name): \(item.value)\n"
        }
        
        return Response(status: statusCode, body: .init(string: """
            <!DOCTYPE html>
                <html>
                    <head>
                        <meta charset="UTF-8" />
                        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
                        <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                        <title>\(statusCode.code)</title>
                    </head>
                    <body>
                        <h1 style="color:red;margin-top:50px;">[\(statusCode.code)] \(errorMessage)</h1>
                        <blockquote>\(detailMessage)</blockquote>
                        <div>
                          <h2>URL:</h2>
                          <pre>\(req.url)</pre>
                        </div>
                        <div>
                          <h2>METHOD:</h2>
                          <pre>\(req.method)</pre>
                        </div>
                        <div>
                          <h2>HEADERS:</h2>
                          <pre>\(headerJsonString)</pre>
                        </div>
                  </body>
            </html>
        """))
    }
    
    private func listen(hostOptions: HostParam) -> (String, String) {
        let host = self.getHost(hostOption: HostParam(port: hostOptions.port, mmid: hostOptions.mmid, subdomain: hostOptions.subdomain))
        let origin = "\(customProtocol)://\(host)"
        
        // TODO: 未完成base64加密
        let token = "dweb-browser-random-token"
        
        self.gatewayMap[host] = PortListener(ipc: nil, host: host, origin: origin)
        return (token, origin)
    }
    
    private func unlisten(hostOptions: HostParam) -> Bool {
        let host = self.getHost(hostOption: HostParam(port: hostOptions.port, mmid: hostOptions.mmid, subdomain: hostOptions.subdomain))
        
        let gateway = self.gatewayMap[host]
        
        if gateway == nil {
            return false
        }
        
        self.tokenMap.removeValue(forKey: host)
        self.gatewayMap.removeValue(forKey: host)
        
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

