//
//  DwebNativeComponent.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/30.
//

import WebKit
import MessageUI
import Foundation
import SwiftUI

typealias IO<I, O> = (I) -> O


/** 原生的微组件 */
class NativeMicroModule: MicroModule {
    typealias IpcCb = (NativeIpc) -> Any
    typealias IpcVoid = () -> Void
    
    override var mmid: MMID {
        get {
            ".sys.dweb"
        }
        set {
            ".sys.dweb"
        }
    }
    private var _connectting_ipcs: Set<NativeIpc> = []
    internal var Routers: [String:(Any) -> Any?] = [:]
    
    func _connect() -> NativeIpc {
        let timestamp = Date().milliStamp
        let port1 = "\(timestamp)_1"
        let port2 = "\(timestamp)_2"
        let inner_ipc = NativeIpc(port1: port2, port2: port1)
        
        _connectting_ipcs.insert(inner_ipc)
        inner_ipc.onClose(cb: {
            self._connectting_ipcs.remove(inner_ipc)
        })()
        
        _emitConnect(ipc:inner_ipc)
        
        return NativeIpc(port1: port1, port2: port2)
    }
    
    internal var _on_connect_cbs: [Int:IpcCb] = [:]
    internal func onConnect(cb: @escaping IpcCb) -> IpcVoid {
        let timestamp = Date().milliStamp
        _on_connect_cbs[timestamp] = cb
        
        return {
            self._on_connect_cbs.removeValue(forKey: timestamp)
        }
    }
    
    internal func _emitConnect(ipc: NativeIpc) {
        for (_, cb) in _on_connect_cbs {
            cb(ipc)
        }
    }
    
    override func after_shutdown() {
        super.after_shutdown()

        for inner_ipc in _connectting_ipcs {
            inner_ipc.close()
        }

        _connectting_ipcs.removeAll()
    }
    
    internal func registerCommonIpcOnMessageHandler(commonHandlerSchema: RequestCommonHandlerSchema) -> () -> Void {
        _initCommonIpcOnMessage()
        var handlers = _common_ipc_on_message_handlers
        let custom_handler_schema: RequestCustomHandlerSchema = RequestCustomHandlerSchema(pathname: commonHandlerSchema.pathname, matchMode: commonHandlerSchema.matchMode, input: self.deserializeRequestToParams(schema: commonHandlerSchema.input), output: self.serializeResultToResponse(schema: commonHandlerSchema.output), handler: commonHandlerSchema.handler)
        
        handlers.insert(custom_handler_schema)
        
        return {
            handlers.remove(custom_handler_schema)
        }
    }
    
    private var _common_ipc_on_message_handlers: Set<RequestCustomHandlerSchema> = []
    private var _inited_common_ipc_on_message = false
    private func _initCommonIpcOnMessage() {
        if _inited_common_ipc_on_message {
            return
        }
        
        _inited_common_ipc_on_message = true
        
        onConnect { ipc in
            ipc.onMessage { request in
                guard let req = request as? IpcRequest else { return false }
                
                if req.type != IPC_DATA_TYPE.request {
                    return false
                }
                
                let pathnames = req.parsed_url?.pathComponents
                guard let pathname = pathnames?.joined(separator: "") else { return false }
                
                var res: IpcResponse?
                
                for handler_schema in self._common_ipc_on_message_handlers {
                    if (handler_schema.matchMode == MatchMode.full
                        ? pathname == handler_schema.pathname
                        : handler_schema.matchMode == MatchMode.prefix
                        ? pathname.hasPrefix(handler_schema.pathname)
                        : false
                    ) {
                        do {
                            let result = handler_schema.handler(handler_schema.input(req), ipc)
                            
                            if let result = result as? IpcResponse {
                                res = result
                            } else {
                                res = handler_schema.output(req, result)
                            }
                        } catch let err {
                            let body: String = "\(err)"
                            
                            res = IpcResponse(req_id: req.req_id, statusCode: 500, body: body, headers: ["Content-Type":"text/plain"])
                        }
                    }
                }
                
                if res == nil {
                    res = IpcResponse(req_id: req.req_id, statusCode: 404, body: "no found handler for '\(pathname)'", headers: ["Content-Type":"text/plain"])
                }
                
                ipc.postMessage(data: res!)
                return true
            }()
        }()
    }
}

extension NativeMicroModule {
    func deserializeRequestToParams(schema: Any) -> (IpcRequest) -> [String:Any] {
        return { request in
            let url = request.parsed_url
            var params: [String:Any] = [:]
            
            guard let schema = schema as? [String:Any] else { return params }
            for (keyname, typename) in schema {
                do {
                    params[keyname] = try self.typeNameParser(key: keyname, typeName: typename, value: url?.urlParameters?[keyname])
                } catch {
                    print(error)
                }
            }
            
            return params
        }
    }
    
    func serializeResultToResponse(schema: Any) -> (IpcRequest, Any) -> IpcResponse {
        return { request, result in
            var body: String = ""
            if let schema = schema as? String {
                do {
                    switch(schema) {
                    case "number":
                        body = String(result as! Int)
                    case "string", "mmid":
                        body = result as! String
                    case "boolean":
                        body = String(result as! Bool)
                    case "dic":
                        body = ChangeTools.dicValueString(result as! [String:Any]) ?? ""
                    default:
                        body = ""
                    }
                } catch {
                    print("serializeResultToResponse result error: \(error)")
                    body = ""
                }
            }
            
            return IpcResponse(req_id: request.req_id, statusCode: 200, body: body, headers: ["Content-Type":"application/json"])
        }
    }
    
    func typeNameParser<T>(key: String, typeName: T, value: String?) throws -> Any? {
        var param: Any?
        
        if value == nil {
            guard let typeName = typeName as? String else {
                throw MicroModuleError.typeError("param type error: '\(key)'.")
            }
            if typeName.hasSuffix("?") {
                throw MicroModuleError.typeError("param type error: '\(key)'.")
            } else {
                param = nil
            }
        } else {
            if let typeName = typeName as? String {
                let typeName = typeName.hasSuffix("?") ? typeName.slice(0, -1) : typeName
                
                switch(typeName) {
                case "number":
                    param = Int(value!)
                case "boolean":
                    param = value == "" ? false : Bool(value!.lowercased())
                case "mmid":
                    if (!value!.hasSuffix(".dweb")) {
                        throw MicroModuleError.typeError("param mmid type error: '\(key)':'\(value!)'")
                    }
                    
                    param = value!
                case "string":
                    param = value!
                default:
                    param = nil
                }
            }
        }
        
        return param
    }
}

enum MatchMode: String {
    case full = "full"
    case prefix = "prefix"
}

struct RequestCommonHandlerSchema {
    var pathname: String
    var matchMode: MatchMode
    var input: [String:Any]
    var output: String
    var handler: ([String:Any], NativeIpc) -> Any
}

struct RequestCustomHandlerSchema: Hashable {
    var pathname: String
    var matchMode: MatchMode
    var input: (IpcRequest) -> [String:Any]
    var output: (IpcRequest, Any) -> IpcResponse
    var handler: ([String:Any], NativeIpc) -> Any
    
    static func == (lhs: RequestCustomHandlerSchema, rhs: RequestCustomHandlerSchema) -> Bool {
        return lhs.pathname == rhs.pathname
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(pathname)
    }
}

