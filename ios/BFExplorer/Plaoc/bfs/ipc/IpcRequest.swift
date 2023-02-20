//
//  IpcRequest.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation
import Vapor

class IpcRequest: IpcBody {
    var type: IPC_DATA_TYPE = IPC_DATA_TYPE.request
    let req_id: Int
    let method: IpcMethod
    let url: String
    let headers: IpcHeaders
    
    init(req_id: Int, method: IpcMethod, url: String, rawBody: RawData, headers: IpcHeaders, ipc: Ipc) {
        self.req_id = req_id
        self.method = method
        self.url = url
        self.headers = headers
        super.init(rawBody: rawBody, ipc: ipc);
    }
    
    var parsed_url: URL? {
        get {
            self.parsed_url ?? URL(string: self.url)
        }
    }
    
    static func fromRequest(req_id: Int, request: Request, ipc: Ipc) -> IpcRequest {
        if request.body.data != nil {
            var data = request.body.data
            return fromBinary(binary: data!.readData(length: data!.readableBytes)!, req_id: req_id, method: IpcMethod.from(vaporMethod: request.method), url: request.url.path, headers: IpcHeaders(request.headers), ipc: ipc)
        } else if request.method == .POST || request.method == .PUT || request.method == .PATCH {
            var ipc_req_body_stream: Data = Data()
            var sequential = request.eventLoop.makeSucceededFuture(())
            
            request.body.drain {
                switch $0 {
                case .buffer(var buffer):
                    if buffer.readableBytes > 0 {
                        ipc_req_body_stream.append(buffer.readData(length: buffer.readableBytes)!)
                    }
                    
                    return sequential
                case .error(_):
                    return sequential
                case .end:
                    return sequential
                }
            }
            
            return fromStream(stream: InputStream(data: ipc_req_body_stream), req_id: req_id, method: IpcMethod.from(vaporMethod: request.method), url: request.url.path, headers: IpcHeaders(request.headers), ipc: ipc, size: nil)
        } else {
            return fromText(rawBody: "", req_id: req_id, method: IpcMethod.from(vaporMethod: request.method), url: request.url.path, headers: IpcHeaders(request.headers), ipc: ipc)
        }
    }
    
    static func fromText(
        rawBody: String,
        req_id: Int,
        method: IpcMethod,
        url: String,
        headers: IpcHeaders,
        ipc: Ipc
    ) -> IpcRequest {
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: RawData(type: .text, data: S_RawData(string: rawBody)), headers: headers, ipc: ipc)
    }
    
    static func fromBinary(
        binary: Data,
        req_id: Int,
        method: IpcMethod,
        url: String,
        headers: IpcHeaders,
        ipc: Ipc
    ) -> IpcRequest {
        let rawBody = ipc.support_message_pack ? RawData(type: .binary, data: S_RawData(data:binary)) : RawData(type: .base64, data: S_RawData(string: simpleDecoder(data: binary, encoding: .base64)))
        var headers = headers
        headers.set(key: "Content-Type", value: "application/octet-stream")
        headers.set(key: "Content-Length", value: "-")
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: rawBody, headers: headers, ipc: ipc)
    }
    
    static func fromStream(
        stream: InputStream,
        req_id: Int,
        method: IpcMethod,
        url: String,
        headers: IpcHeaders,
        ipc: Ipc,
        size: Int64?
    ) -> IpcRequest {
        var headers = headers
        headers.set(key: "Content-Type", value: "application/octet-stream")
        
        if size != nil {
            headers.set(key: "Content-Length", value: "\(size!)")
        }
        let stream_id = "res/\(req_id)/\(headers.getOrDefault(key: "Content-Length", defaultValue: "-")))"
        
        let rawBody = ipc.support_message_pack ? RawData(type: .binary, data: S_RawData(string: stream_id)) : RawData(type: .base64, data: S_RawData(string: stream_id))
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: rawBody, headers: headers, ipc: ipc)
    }
    
    func asRequest(method: IpcMethod, url: String) -> Request {
        Request(application: HttpServer.app, method: HTTPMethod(rawValue: method.rawValue), url: URI(string: url), on: HttpServer.app.eventLoopGroup as! EventLoop)
    }
}

extension IpcRequest: IpcMessage {}


