//
//  Ipc.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

var ipc_uid_acc = 0
class Ipc {
    typealias IpcTupleAny = () -> Any
    typealias IpcTupleVoid = () -> Void
    
    
    var support_message_pack: Bool
    var uid: Int = ipc_uid_acc++
    var remote: MicroModule
    var role: IPC_ROLE
    
    init() {
        support_message_pack = false
        remote = NativeMicroModule()
        role = IPC_ROLE.client
    }

    internal var _messageSignal = IpcSignal.createSignal()
    func postMessage(message: IpcMessage) -> Void {
        if self._closed {
            return
        }
        
        self._doPostMessage(data: message)
    }
    func _doPostMessage(data: IpcMessage) {}
    
    func onMessage(cb: @escaping OnIpcMessage) -> IpcTupleVoid {
        return self._messageSignal.listen(cb: cb)
    }
    
    private var _closed = false
    private var _closeSignal = IpcCloseSignal.createSignal()
    
    func _doClose() {}
    
    func close() {
        if self._closed {
            return
        }
        
        self._closed = true
        self._doClose()
        self._closeSignal.emit()
    }
    
    func onClose(cb: @escaping IpcTupleAny) ->IpcTupleVoid {
        return self._closeSignal.listen(cb: cb)
    }
    
    private var _reqresMap: [Int:IpcResponse] = [:]
    private var _req_id_acc = 0
    func allocReqId() -> Int {
        return self._req_id_acc++
    }
    
    private var _inited_req_res = false
    private func _initReqRes() {
        if self._inited_req_res {
            return
        }
        
        self._inited_req_res = true
        self.onMessage { message, _  in
            guard let message = message as? IpcResponse else  { return }
            self._reqresMap[message.req_id] = message
        }()
    }
    
    func request(url: String) {
        
    }
}
