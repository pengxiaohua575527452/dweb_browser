//
//  IpcResponse.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation
import Vapor

class IpcResponse: IpcBody {
    var type: IPC_DATA_TYPE = IPC_DATA_TYPE.response
    let req_id: Int
    let statusCode: Int
    var headers: IpcHeaders
    
    init(req_id: Int, statusCode: Int, rawBody: RawData, headers: IpcHeaders, ipc: Ipc) {
        self.req_id = req_id
        self.statusCode = statusCode
        self.headers = headers
        super.init(rawBody: rawBody, ipc: ipc)
    }
    
    func asResponse() -> Response {
        var body: Response.Body
        
        if self.body is String {
            body = .init(string: self.body as! String)
        } else if self.body is Data {
            body = .init(data: self.body as! Data)
        } else if self.body is InputStream {
            body = .init(stream: { writer in
                var stream = self.body as! InputStream
                let bufferSize = 1024
                stream.open()
                
                while stream.hasBytesAvailable {
                    var data = Data()
                    var buffer = [UInt8](repeating: 0, count: bufferSize)
                    let bytesRead = stream.read(&buffer, maxLength: bufferSize)
                    if bytesRead < 0 {
                        stream.close()
                        _ = writer.write(.error("Error reading from stream" as! Error))
                    } else if bytesRead == 0 {
                        stream.close()
                        _ = writer.write(.end)
                    }
                    data.append(buffer, count: bytesRead)
                    var byteBuffer = ByteBuffer(data: data)
                    _ = writer.write(.buffer(byteBuffer))
                }
            })
        } else {
            fatalError("invalid body to response: \(self.body)")
        }
        
        return Response(status: HTTPResponseStatus(statusCode: statusCode), headers: headers.toHTTPHeaders(), body: body)
    }
    
    static func fromJson(req_id: Int, statusCode: Int, jsonAble: [String:Any], headers: IpcHeaders, ipc: Ipc) -> IpcResponse {
        return fromText(req_id: req_id, statusCode: statusCode, text: ChangeTools.dicValueString(jsonAble)!, headers: headers, ipc: ipc)
    }
    
    static func fromText(req_id: Int, statusCode: Int, text: String, headers: IpcHeaders, ipc: Ipc) -> IpcResponse {
        return IpcResponse(req_id: req_id, statusCode: statusCode, rawBody: RawData(type: .text, data: S_RawData(string: text)), headers: headers, ipc: ipc)
    }
    
    static func fromBinary(req_id: Int, statusCode: Int, binary: Data, headers: IpcHeaders, ipc: Ipc) -> IpcResponse {
        var headers = headers
        headers.set(key: "Content-Type", value: "application/octet-stream")
        headers.set(key: "Content-Length", value: "\(binary.count)")
        
        return IpcResponse(req_id: req_id, statusCode: statusCode, rawBody: ipc.suport_bianry ? RawData(type:.binary, data:S_RawData(data:binary)) : RawData(type:.base64, data: S_RawData(string: binary.base64EncodedString())), headers: headers, ipc: ipc)
    }
    
    static func fromStream(req_id: Int, statusCode: Int, stream: InputStream, headers: IpcHeaders, ipc: Ipc) -> IpcResponse {
        var headers = headers
        headers.set(key: "Content-Type", value: "application/octet-stream")
        let stream_id = "res/\(req_id)/\(headers.getOrDefault(key: "Content-Length", defaultValue: "-"))"
        let ipcResponse = IpcResponse(req_id: req_id, statusCode: statusCode, rawBody: ipc.suport_bianry ? RawData(type:.binary_stream_id, data: S_RawData(string: stream_id)) : RawData(type: .base64_stream_id, data: S_RawData(string: stream_id)), headers: headers, ipc: ipc)
        
        Task.init {
            await streamAsRawData(stream_id: stream_id, stream: stream, ipc: ipc)
        }
        
        
        return ipcResponse
    }
    
    static func fromResponse(req_id: Int, response: Response, ipc: Ipc) -> IpcResponse {
        return fromStream(req_id: req_id, statusCode: Int(response.status.code), stream: InputStream(data: response.body.data!), headers: IpcHeaders(response.headers), ipc: ipc)
    }
}

extension IpcResponse: IpcMessage {}
