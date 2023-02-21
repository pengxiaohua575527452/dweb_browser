//
//  MessagePortIpc.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/20.
//

import Foundation
import Combine

class MessagePortIpc: Ipc {
    let port: PassthroughSubject<Any, Never>
    private var cancellable: AnyCancellable?
    
    init(port: PassthroughSubject<Any, Never>, remote: MicroModule, role: IPC_ROLE) {
        self.port = port
        super.init()
        self.remote = remote
        self.role = role

        let ipc = self
        cancellable = port.sink { message in
            Task {
                if let message = message as? String, message == "close" {
                    await self.close()
                } else if let message = message as? IpcMessage {
                    self._messageSignal.emit((message, ipc))
                }
            }
        }
    }
    
    override func _doPostMessage(data: IpcMessage) {
        let message = JSONStringify(data)
        
        if message != nil {
            port.send(message!)
        }
    }
    
    override func _doClose() async {
        port.send("close")
        cancellable?.cancel()
    }
}
