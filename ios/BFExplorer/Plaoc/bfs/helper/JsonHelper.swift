//
//  JsonHelper.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/20.
//

import Foundation

/// 序列化
func JSONStringify<T: Codable>(_ data: T) -> String? {
    do {
        let jsonData = try JSONEncoder().encode(data)
        return String(data: jsonData, encoding: .utf8)
    } catch {
        fatalError("data JSONStringify error: \(data)")
    }
    return nil
}

/// 反序列化
func JSONParse<T: Codable>(_ str: String) -> T? {
    do {
        let jsonData = str.utf8Data()
        
        if jsonData == nil {
            return nil
        }
        
        return try JSONDecoder().decode(T.self, from: jsonData!)
    } catch {
        fatalError("data JSONParse error: \(str)")
    }
    
    
    return nil
}

func jsonToIpcMessage(data: String, ipc: Ipc) -> Any? {
    if data == "close" {
        return data
    }
    
    let jsonData = data.utf8Data()
    
    if jsonData == nil {
        return nil
    }
    
    do {
        let decoder = JSONDecoder()
        let message = try decoder.decode(IpcMessageData.self, from: jsonData!)
        
        if message.type == .request {
            let req = try decoder.decode(IpcRequest.self, from: jsonData!)
            return IpcRequest(req_id: req.req_id, method: req.method, url: req.url, rawBody: req.rawBody, headers: req.headers, ipc: ipc)
        } else if message.type == .response {
            let res = try decoder.decode(IpcResponse.self, from: jsonData!)
            return IpcResponse(req_id: res.req_id, statusCode: res.statusCode, rawBody: res.rawBody, headers: res.headers, ipc: ipc)
        } else if message.type == .stream_data {
            let sdata = try decoder.decode(IpcStreamData.self, from: jsonData!)
            return IpcStreamData(stream_id: sdata.stream_id, data: sdata.data)
        } else if message.type == .stream_pull {
            let pdata = try decoder.decode(IpcStreamPull.self, from: jsonData!)
            return IpcStreamPull(stream_id: pdata.stream_id, desiredSize: pdata.desiredSize)
        } else if message.type == .stream_end {
            let edata = try decoder.decode(IpcStreamEnd.self, from: jsonData!)
            return IpcStreamEnd(stream_id: edata.stream_id)
        } else if message.type == .stream_abort {
            let adata = try decoder.decode(IpcStreamAbort.self, from: jsonData!)
            return IpcStreamAbort(stream_id: adata.stream_id)
        }
        
        return data
    } catch {
        return data
    }
}

