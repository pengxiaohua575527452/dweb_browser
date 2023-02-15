//
//  IpcRequest.swift
//  IPC
//
//  Created by ui03 on 2023/2/13.
//

import UIKit

class IpcRequest: IpcBody {

    private let type = IPC_DATA_TYPE.REQUEST
    var parsed_url: URL?
    
    init(req_id: Int, method: String, url: String, rawBody: RawData, headers: [String:String], ipc: Ipc?) {
        super.init(rawBody: rawBody, ipc: ipc)
    }
    
    //TODO
//    func parsed_url() -> String {
//        return self.parsed_url ?? ""
//    }

    
    static func fromText(text: String,req_id: Int,method: String,url: String,headers:[String:String]) -> IpcRequest {
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: RawData(raw: .TEXT, content: text), headers: headers, ipc: nil)
    }
    
    static func fromBinary(binary: [UInt8],req_id: Int,method: String,url: String,headers:[String:String], ipc: Ipc) -> IpcRequest {
        
        var headDict = headers
        headDict["Content-Type"] = "application/octet-stream"
        headDict["Content-Length"] = "\(binary.count)"
        
        let data = Data(bytes: binary, count: binary.count)
        let result = String(data: data, encoding: .utf8) ?? ""
        
        let rawBody = (ipc.support_message_pack ?? false) ? RawData(raw: .BINARY, content: result) : RawData(raw: .BASE64, content: encoding.simpleDecoder(data: binary, encoding: .base64) ?? "")
        
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: rawBody, headers: headers, ipc: ipc)
    }
    
    static func fromStream(stream: Data,req_id: Int,method: String,url: String,headers:[String:String], ipc: Ipc) -> IpcRequest {
        
        var headDict = headers
        headDict["Content-Type"] = "application/octet-strea"
        
        let stream_id = "res/\(req_id)/\(headDict["content-length"] ?? "-")"
        //TODO streamAsRawData
        
        let rawBody = (ipc.support_message_pack ?? false) ? RawData(raw: .BINARY_STREAM_ID, content: stream_id) : RawData(raw: .BASE64_STREAM_ID, content: stream_id)
        
        return IpcRequest(req_id: req_id, method: method, url: url, rawBody: rawBody, headers: headDict, ipc: ipc)
    }
    
}
