//
//  DwebNativeComponent.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/30.
//

import WebKit
import MessageUI
import Foundation

typealias IO<I, O> = (I) -> O
typealias IpcClosure = (Ipc) -> Any


/** 原生的微组件 */
class NativeMicroModule: MicroModule {
    override var mmid: MMID {
        get {
            ".sys.dweb"
        }
        set {
            ".sys.dweb"
        }
    }
    private var _connectting_ipcs: Set<Ipc> = []
    internal var Routers: [String:(Any) -> Any?] = [:]
    
    func _connect() {
        
    }
    
    internal var _on_connect_cbs: [Int:IpcClosure] = [:]
    
    // todo
    internal func onConnect(closure:@escaping IpcClosure) {
//    internal func onConnect(closure:@escaping IpcClosure) -> () -> Void {
//        connectId += 1
//        _on_connect_cbs[connectId] = closure
//
//        return {
//
//            if let index = _on_connect_cbs.firstIndex(where: { cls in
//                return closure == cls
//            }) {
//                self._on_connect_cbs.remove(at: index)
//            }
//        }
        
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
        handlers.insert(commonHandlerSchema)
        
        return {
            handlers.remove(commonHandlerSchema)
        }
    }
    
    private var _common_ipc_on_message_handlers: Set<RequestCommonHandlerSchema> = []
    private var _inited_common_ipc_on_message = false
    private func _initCommonIpcOnMessage() {
        if _inited_common_ipc_on_message {
            return
        }
        
        _inited_common_ipc_on_message = true
        
        onConnect { ipc in
            ipc.onMessage { request in
                guard let req = request as? IpcRequest else { return }

                let pathnames = req.parsed_url?.pathComponents
                guard let pathname = pathnames?.joined(separator: "") else { return }
                
                var res: IpcResponse?
                
                for handler_schema in self._common_ipc_on_message_handlers {
                    if (
                        handler_schema.matchMode == MatchMode.full
                        ? pathname == handler_schema.pathname
                        : handler_schema.matchMode == MatchMode.prefix
                        ? pathname.hasPrefix(handler_schema.pathname)
                        : false
                    ) {
                        let result = handler_schema.handler(req, ipc: ipc)
                        if result is IpcResponse {
                            res = result as! IpcResponse
                        } else {
                            // todo
//                            res =
                        }
                    }
                }
                
                if res == nil {
                    res = IpcResponse(req_id: req.req_id, statusCode: 404, body: "no found handler for '\(pathname)'", headers: ["Content-Type": "text/plain"])
                }
                
                return ipc.postMessage(data: res!)
            }
        }
    }
    
}

extension NativeMicroModule {
    private func deserializeRequestToParams() -> (IpcRequest) -> [String:Any] {
        return { req in
            // todo
            let url = req.parsed_url
            
            return req.toDic()
        }
    }
    
    private func serializeResultToResponse() -> (IpcRequest, Any) -> IpcResponse {
        return {req, result in
            return IpcResponse(req_id: req.req_id, statusCode: 200, body: ChangeTools.dicValueString(result as! [String : Any])!, headers: ["Content-Type": "application/json"])
        }
    }
}

enum MatchMode: String {
    case full = "full"
    case prefix = "prefix"
}

struct RequestCommonHandlerSchema: Hashable {
    var pathname: String
    var matchMode: MatchMode
    func handler(_ args: Any, ipc: Ipc) -> Any? {
        return nil
    }
}




