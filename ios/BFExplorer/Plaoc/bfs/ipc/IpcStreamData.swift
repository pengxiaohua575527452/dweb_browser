//
//  IpcStreamData.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

struct IpcStreamData {
    var type: IPC_DATA_TYPE = IPC_DATA_TYPE.stream_data
}

extension IpcStreamData: IpcMessage {}
