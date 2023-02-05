//
//  BfsTypes.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/30.
//

import Foundation
import Combine

typealias MMID = String
enum MicroModuleError: Error {
    case moduleError(String)
    case portError(String)
    case workerError(Int)
    case processError(String)
    case typeError(String)
}

enum IPC_DATA_TYPE: Int {
    case request = 0
    case response = 1
}

enum IPC_STATUS: String {
    case connect = "connect"
    case close = "close"
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
    
    func toDic() -> [String:Any] {
        var params: [String:Any] = [:]
        
        params["type"] = IPC_DATA_TYPE.response
        params["req_id"] = req_id
        params["statusCode"] = statusCode
        params["body"] = body
        params["headers"] = headers
        
        return params
    }
}

protocol IpcIntersectionType {
    func toDic() -> [String:Any]
}
extension IpcRequest: IpcIntersectionType {}
extension IpcResponse: IpcIntersectionType {}



typealias IpcCb = (IpcIntersectionType) -> Any
typealias IpcCloseCb = () -> Any
typealias IpcVoid = () -> Void

protocol Ipc: Hashable {
    var port1: String { get }
    var port2: String { get }
    func postMessage(data: IpcIntersectionType) -> Void
    func onMessage(cb: @escaping IpcCb) -> IpcVoid
    func close() -> Void
    func onClose(cb: @escaping IpcCloseCb) -> IpcVoid
}

class NativeIpc: Ipc {
    var port1: String
    var port2: String
    private var publisher: NotificationCenter.Publisher
    private var cancelIpc: AnyCancellable?
    
    init(port1: String, port2: String) {
        self.port1 = port1
        self.port2 = port2
        
        publisher = NotificationCenter.default
            .publisher(for: Notification.Name(port1), object: nil)
        cancelIpc = publisher.sink { noti in
            guard let userInfo = noti.userInfo else { return }
            guard let status = userInfo["status"] as? IPC_STATUS else { return }
            
            if status == IPC_STATUS.close {
                self.close()
            } else if (status == IPC_STATUS.connect) {
                guard let data = userInfo["data"] as? [String:Any], let type = data["type"] as? IPC_DATA_TYPE else { return }
                var message: IpcIntersectionType?
                
                if type == IPC_DATA_TYPE.request {
                    guard let req_id = data["req_id"] as? Int, let method = data["method"] as? String, let url = data["url"] as? String,
                          let body = data["body"] as? String, let headers = data["headers"] as? [String:String] else { return }
                    message = IpcRequest(req_id: req_id, method: method, url: url, body: body, headers: headers)
                } else if type == IPC_DATA_TYPE.response {
                    guard let req_id = data["req_id"] as? Int, let statusCode = data["statusCode"] as? Int, let body = data["body"] as? String, let headers = data["headers"] as? [String:String] else { return }
                    message = IpcResponse(req_id: req_id, statusCode: statusCode, body: body, headers: headers)
                }
                
                if message != nil {
                    for (_, cb) in self._cbs {
                        cb(message!)
                    }
                }
            }
        }
    }
    
    
    func postMessage(data: IpcIntersectionType) {
        if _closed {
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name(port2), object: nil, userInfo: ["status": IPC_STATUS.connect, "data": data.toDic()])
    }
    
    private var _cbs: [Int:IpcCb] = [:]
    func onMessage(cb: @escaping IpcCb) -> IpcVoid {
        let timestamp = Date().milliStamp
        _cbs[timestamp] = cb
        
        return {
            self._cbs.removeValue(forKey: timestamp)
        }
    }
    
    private var _closed = false
    func close() {
        if _closed {
            return
        }
        
        _closed = true
        NotificationCenter.default.post(name: Notification.Name(port2), object: nil, userInfo: ["status": IPC_STATUS.close])
        
        if cancelIpc != nil {
            cancelIpc!.cancel()
        }
        
        for (_, cb) in _onclose_cbs {
            cb()
        }
    }
    
    private var _onclose_cbs: [Int:IpcCloseCb] = [:]
    func onClose(cb: @escaping IpcCloseCb) -> IpcVoid {
        let timestamp = Date().milliStamp
        _onclose_cbs[timestamp] = cb
        
        return {
            self._onclose_cbs.removeValue(forKey: timestamp)
        }
    }
    
    static func == (lhs: NativeIpc, rhs: NativeIpc) -> Bool {
        return lhs.port1 == rhs.port1
    }
}

extension NativeIpc: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(port1)
    }
}


