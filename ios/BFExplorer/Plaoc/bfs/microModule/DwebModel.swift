//
//  BfsTypes.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/30.
//

import Foundation

enum IPC_DATA_TYPE: Int {
    case request = 0
    case response = 1
}

struct IpcRequest {
    var type = IPC_DATA_TYPE.request
    var req_id: Int
    var method: String
    var url: String
    var body: String
    var headers: [String:String]
    func onResponse(response: IpcResponse) {}
    var parsed_url: URL? {
        get {
            return URL(string: url) ?? nil
        }
    }
    
    func toDic() -> [String:Any] {
        var params: [String:Any] = [:]
        
        params["type"] = IPC_DATA_TYPE.request
        params["req_id"] = req_id
        params["method"] = method
        params["url"] = url
        params["body"] = body
        params["headers"] = headers
        
        return params
    }
}

struct IpcResponse {
    var type = IPC_DATA_TYPE.response
    var req_id: Int
    var statusCode: Int
    var body: String
    var headers: [String:String]
}

protocol IpcIntersectionType {}
extension IpcRequest: IpcIntersectionType {}
extension IpcResponse: IpcIntersectionType {}

var ipc_uid_acc = 0
struct Ipc: Hashable {
    var uid: Int {
        get {
            ipc_uid_acc += 1
            return ipc_uid_acc
        }
    }
    func postMessage(data: IpcIntersectionType) -> Void {}
    func onMessage(closure: (IpcIntersectionType) -> Any) -> () -> Bool {
        return {
            return true
        }
    }
    func close() -> Void {}
    func onClose(closure: () -> Any) -> () -> Bool {
        return {
            return true
        }
    }
}


