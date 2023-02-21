//
//  IpcRequest.swift
//  IPC
//
//  Created by ui03 on 2023/2/13.
//

import UIKit
import AsyncHTTPClient

class IpcRequest: IpcBody {

    private let type = IPC_DATA_TYPE.REQUEST
    var parsed_url: URL?
    private var urlString: String = ""
    
    override init() {
        super.init()
    }
    
    init(req_id: Int, method: String, url: String, rawBody: RawData, headers: IpcHeaders, ipc: Ipc?) {
        super.init(rawBody: rawBody, ipc: ipc)
        self.urlString = url
    }
    
    
    func parsed_urlAction() -> URL? {
        return self.parsed_url ?? urlHelper.parseUrl(urlString: self.urlString)
    }

    
    static func fromText(text: String,req_id: Int,method: String,url: String,headers: IpcHeaders) -> IpcRequest {
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: RawData(raw: .TEXT, content: text), headers: headers, ipc: nil)
    }
    
    static func fromBinary(binary: [UInt8],req_id: Int,method: String,url: String,headers:IpcHeaders, ipc: Ipc) -> IpcRequest {
        
        headers.set(key: "Content-Type", value: "application/octet-stream")
        headers.set(key: "Content-Length", value: "\(binary.count)")
        
        let rawBody = (ipc.support_message_pack ?? false) ? RawData(raw: .BINARY, content: binary) : RawData(raw: .BASE64, content: encoding.simpleDecoder(data: binary, encoding: .base64) ?? "")
        
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: rawBody, headers: headers, ipc: ipc)
    }
    
    static func fromStream(stream: InputStream,req_id: Int,method: String,url: String,headers:IpcHeaders, ipc: Ipc) -> IpcRequest {
        
        headers.set(key: "Content-Type", value: "application/octet-stream")
        
        let stream_id = "res/\(req_id)/\(headers.getValue(forKey: "content-length") ?? "-")"
        
        streamAsRawData.streamAsRawData(streamId: stream_id, stream: stream, ipc: ipc)
        
        let rawBody = (ipc.support_message_pack ?? false) ? RawData(raw: .BINARY_STREAM_ID, content: stream_id) : RawData(raw: .BASE64_STREAM_ID, content: stream_id)
        
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: rawBody, headers: headers, ipc: ipc)
    }
    
}

extension IpcRequest: IpcMessage {}
