package info.bagen.rust.plaoc.microService.ipc

import info.bagen.rust.plaoc.microService.ipc.helper.IPC_DATA_TYPE
import info.bagen.rust.plaoc.microService.ipc.helper.SimpleEncoding
import info.bagen.rust.plaoc.microService.ipc.helper.simpleDecoder

/** 处理ipc流数据*/
class IpcStreamData(val stream_id: String, val data: Any) {
  val  type = IPC_DATA_TYPE.STREAM_DATA;
    /** ipc流数据转化为二进制*/
   fun fromBinary(ipc: Ipc, stream_id: String, data: ByteArray): IpcStreamData {
        if (ipc.supportMessagePack) {
            return  IpcStreamData(stream_id, data);
        }
        return  IpcStreamData(stream_id, simpleDecoder(data, SimpleEncoding.base64));
    }
}