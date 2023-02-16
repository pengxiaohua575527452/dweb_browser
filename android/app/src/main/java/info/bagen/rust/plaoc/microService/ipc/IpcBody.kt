package info.bagen.rust.plaoc.microService.ipc

import java.io.InputStream
import java.util.stream.Stream

class IpcBody(var rawBody: RawData, ipc: Ipc) {
    object Body {
       var data: Any? = null
        var u8a: ByteArray? = null
        var stream: InputStream? =null
        var text: String? = null
    }

}

typealias  RawData = IPC_RAW_BODY_TYPE

 enum class  IPC_RAW_BODY_TYPE(val type:Int,var value:Any? = null) {
    /** 文本 json html 等 */
    TEXT(1 shl 1),
    /** 使用文本表示的二进制 */
    BASE64(1 shl 2),
    /** 二进制 */
    BINARY(1 shl 3),
    /** 流 */
    STREAM_ID(1 shl 4),
    /** 文本流 */
    TEXT_STREAM_ID( STREAM_ID.type or TEXT.type),
    /** 文本二进制流 */
    BASE64_STREAM_ID(STREAM_ID.type or BASE64.type),
    /** 二进制流 */
    BINARY_STREAM_ID(STREAM_ID.type or BINARY.type),
}
