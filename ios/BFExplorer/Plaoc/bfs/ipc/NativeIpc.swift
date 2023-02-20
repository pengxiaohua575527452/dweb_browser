//
//  NativeIpc.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/20.
//

import Foundation
import Combine

class NativeIpc: Ipc {
    let port: NativePort<IpcMessage, IpcMessage>
    
    init(port: NativePort<IpcMessage, IpcMessage>, remote: MicroModule, role: IPC_ROLE) {
        self.port = port
        super.init()
        self.remote = remote
        self.role = role
        
        _ = port.onMessage { message in
            var ipcMessage: IpcMessage
            if let fromRequest = message as? IpcRequest {
                ipcMessage = IpcRequest.fromRequest(req_id: fromRequest.req_id, request: fromRequest.asRequest(method: fromRequest.method, url: fromRequest.url), ipc: self)
            } else if let fromResponse = message as? IpcResponse {
                ipcMessage = IpcResponse.fromResponse(req_id: fromResponse.req_id, response: fromResponse.asResponse(), ipc: self)
            } else {
                ipcMessage = message
            }
            
            self._messageSignal.emit((ipcMessage, self))
            return nil
        }
        
        port.start()
    }
    
    override func _doPostMessage(data: IpcMessage) {
        port.postMessage(msg: data)
    }
    
    override func _doClose() async {
        port.close()
    }
}


class NativePort<I, O> {
    private let channel_in: PassthroughSubject<I, Never>
    private let channel_out: PassthroughSubject<O, Never>
    private let semaphore: DispatchSemaphore
    private var cancellable: AnyCancellable?
    
    init(channel_in: PassthroughSubject<I, Never>, channel_out: PassthroughSubject<O, Never>, semaphore: DispatchSemaphore) {
        self.channel_in = channel_in
        self.channel_out = channel_out
        self.semaphore = semaphore
        
        Task {
            semaphore.wait()
            closing = true
            cancellable?.cancel()
            _closeSignal.emit(())
        }
    }
    
    private var started = false
    
    func start() {
        if started || closing {
            return
        } else {
            started = true
        }
        
        Task {
            cancellable = channel_in.sink { message in
                self._messageSignal.emit(message)
            }
        }
    }
    
    private let _closeSignal = Signal<()>()
    
    private var closing = false
    
    func close() {
        if closing {
            return
        } else {
            closing = true
        }
    }
    
    private let _messageSignal = Signal<I>()
    
    func postMessage(msg: O) {
        channel_out.send(msg)
    }
    
    func onMessage(cb: @escaping (I) -> SIGNAL_CTOR?) -> () -> Bool {
        self._messageSignal.listen(cb)
    }
}


struct NativeMessageChannel<T1, T2> {
    private let semaphore = DispatchSemaphore(value: 0)
    private let channel1 = PassthroughSubject<T1, Never>()
    private let channel2 = PassthroughSubject<T2, Never>()
    let port1: NativePort<T1, T2>
    let port2: NativePort<T2, T1>
    
    init() {
        port1 = NativePort(channel_in: channel1, channel_out: channel2, semaphore: semaphore)
        port2 = NativePort(channel_in: channel2, channel_out: channel1, semaphore: semaphore)
    }
}
