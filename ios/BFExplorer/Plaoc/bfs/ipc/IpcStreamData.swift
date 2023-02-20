//
//  IpcStreamData.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

struct IpcStreamData {
    var type: IPC_DATA_TYPE = IPC_DATA_TYPE.stream_data
    let stream_id: String
    let data: Any
    
    init(stream_id: String, data: Any) {
        self.stream_id = stream_id
        self.data = data
    }
    
    static func fromBinary(ipc: Ipc, stream_id: String, data: Data) -> IpcStreamData {
        if ipc.support_message_pack {
            return IpcStreamData(stream_id: stream_id, data: data)
        }
        
        return IpcStreamData(stream_id: stream_id, data: data.base64EncodedString())
    }
}

extension IpcStreamData: IpcMessage {}
