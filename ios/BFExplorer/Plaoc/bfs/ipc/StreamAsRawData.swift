//
//  StreamAsRawData.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/16.
//

import Foundation
import Vapor

func streamAsRawData(stream_id: String, stream: InputStream, ipc: Ipc) async {
    return await withCheckedContinuation { continuation in
        let byteChannel = EmbeddedChannel()
        stream.open()

        _ = ipc.onMessage { (message, ipc) in
            if let message = message as? IpcStreamPull, message.stream_id == stream_id {
                if message.desiredSize != nil {
                    var buffer = byteChannel.allocator.buffer(capacity: 16000)
                    stream.read(&buffer, maxLength: message.desiredSize!)
                    ipc.postMessage(message: IpcStreamData(stream_id: stream_id, data: buffer))
                }
            } else if let message = message as? IpcStreamAbort, message.stream_id == stream_id {
                stream.close()
                _ = byteChannel.closeFuture
                continuation.resume()
            }
            
            return nil
        }
    }
}

func rawDataToBody(rawBody: RawData, ipc: Ipc) -> Any {
    var bodyEncoder: (Any) -> Any
    bodyEncoder = ((rawBody.type.rawValue & IPC_RAW_BODY_TYPE.binary.rawValue) != 0)
        ? { data in return data as! Data }
        : ((rawBody.type.rawValue & IPC_RAW_BODY_TYPE.base64.rawValue) != 0)
        ? { data in return (data as! String).to_b64_data()! }
        : ((rawBody.type.rawValue & IPC_RAW_BODY_TYPE.text.rawValue) != 0)
        ? { data in return (data as! String).to_utf8_data()! }
        : { data in fatalError("invalid rawBody type: \(rawBody.type)")}
    
    if (rawBody.type.rawValue & IPC_RAW_BODY_TYPE.stream_id.rawValue) != 0 {
        let stream_id = rawBody.data.string!
        var stream: InputStream?
        
        let semaphore = DispatchSemaphore(value: 1)
        
        _ = ipc.onMessage { (message, ipc) in
            if let message = message as? IpcStreamData, message.stream_id == stream_id {
                var data = bodyEncoder(message.data) as! Data
                stream = InputStream(data: data)
                semaphore.signal()
            } else if let message = message as? IpcStreamEnd, message.stream_id == stream_id {
                return .OFF
            }
            
            return nil
        }
        
        semaphore.wait()
        
        return stream!
    } else if (rawBody.type.rawValue & IPC_RAW_BODY_TYPE.text.rawValue) != 0 {
        return rawBody.data.string!
    } else {
        return bodyEncoder(rawBody.data.data!)
    }
}
