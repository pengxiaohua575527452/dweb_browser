//
//  IpcStreamPull.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

struct IpcStreamPull {
    var type: IPC_DATA_TYPE = IPC_DATA_TYPE.stream_pull
    let stream_id: String
    var desiredSize: Int?
    
    init(stream_id: String, desiredSize: Int?) {
        var _deisredSize = desiredSize
        if _deisredSize == nil {
            _deisredSize = 1
        } else if _deisredSize! < 1 {
            _deisredSize = 1
        }
        
        self.desiredSize = _deisredSize
    }
}

extension IpcStreamPull: IpcMessage {}
