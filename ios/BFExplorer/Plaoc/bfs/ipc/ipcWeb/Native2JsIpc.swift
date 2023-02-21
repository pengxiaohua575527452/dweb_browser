//
//  Native2JsIpc.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/20.
//

import Foundation
import Combine

var ALL_IPC_CACHE: [Int:PassthroughSubject<Any, Never>] = [:]
var all_ipc_id_acc = 0

func saveNative2JsIpcPort(port: PassthroughSubject<Any, Never>) {
    let port_id = all_ipc_id_acc++
    ALL_IPC_CACHE[port_id] = port
}

class Native2JsIpc: MessagePortIpc {
    var port_id: Int
    
    init(port_id: Int, remote: MicroModule) {
        self.port_id = port_id
        let port = ALL_IPC_CACHE[port_id]
        super.init(port: port!, remote: remote, role: .client)
    }
}
