//
//  Ipc.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation
import Vapor
import Combine

var ipc_uid_acc = 0
class Ipc {
    typealias IpcTupleCtor = () -> SIGNAL_CTOR
    typealias IpcTupleBool = () -> Bool
    
    var uid: Int = ipc_uid_acc++
    /**
     * 是否支持 messagePack 协议传输：
     * 需要同时满足两个条件：通道支持直接传输二进制；通达支持 MessagePack 的编解码
     */
    var support_message_pack: Bool
    /**
     * 是否支持 Protobuf 协议传输：
     * 需要同时满足两个条件：通道支持直接传输二进制；通达支持 Protobuf 的编解码
     */
    var support_protobuf: Bool
    /** 是否支持 二进制 传输 */
    var suport_bianry: Bool {
        get {
            return support_message_pack || support_protobuf
        }
    }
    var remote: MicroModule
    var role: IPC_ROLE
    
    init() {
        support_message_pack = false
        support_protobuf = false
        remote = NativeMicroModule()
        role = IPC_ROLE.client
//        onMessage = _messageSignal.listen
    }

    internal var _messageSignal = Signal<(IpcMessage, Ipc)>()
    func postMessage(message: IpcMessage) -> Void {
        if self._closed {
            return
        }
        
        self._doPostMessage(data: message)
    }
    
//    var onMessage: ((@escaping OnIpcMessage) -> IpcTupleBool)
    func onMessage(cb: @escaping OnIpcMessage) -> IpcTupleBool {
        return _messageSignal.listen(cb)
    }
    func _doPostMessage(data: IpcMessage) {}
    
    private lazy var _getOnRequestListener = {
        let signal = Signal<(IpcMessage, Ipc)>()
        _ = _messageSignal.listen { (message, ipc) in
            if let message = message as? IpcRequest {
                signal.emit((message, ipc))
            }
        }

        return signal.listen
    }()
    
    
    func onRequest(cb: @escaping ((IpcMessage, Ipc)) -> SIGNAL_CTOR) -> IpcTupleBool {
        return _getOnRequestListener(cb)
    }
    
    private var _closed = false
    private var _closeSignal = Signal<()>()
    
    func _doClose() async {}
    
    func close() async {
        if self._closed {
            return
        }
        
        self._closed = true
        await self._doClose()
        self._closeSignal.emit(())
    }
    
    func onClose(cb: @escaping IpcTupleCtor) -> IpcTupleBool {
        return self._closeSignal.listen(cb)
    }
    
    func request(request: Request) async -> IpcResponse {
        return await withCheckedContinuation { continuation in
            var req_id = allocReqId()
            
            self.postMessage(message: IpcRequest.fromRequest(req_id: req_id, request: request, ipc: self))
            
            _ = self.onMessage { (message, ipc) in
                if let message = message as? IpcResponse, req_id == message.req_id {
                    continuation.resume(returning: message)
                }
            }
        }
    }
    private var _req_id_acc = 0
    func allocReqId() -> Int {
        return self._req_id_acc++
    }
    
}
