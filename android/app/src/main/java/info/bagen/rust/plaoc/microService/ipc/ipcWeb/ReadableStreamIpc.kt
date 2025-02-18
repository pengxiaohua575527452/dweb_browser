package info.bagen.rust.plaoc.microService.ipc.ipcWeb

import info.bagen.rust.plaoc.microService.core.MicroModule
import info.bagen.rust.plaoc.microService.helper.*
import info.bagen.rust.plaoc.microService.ipc.*
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.io.InputStream


inline fun debugStreamIpc(tag: String, msg: Any = "", err: Throwable? = null) =
    printdebugln("stream-ipc", tag, msg, err)

/**
 * 基于 WebReadableStream 的IPC
 *
 * 它会默认构建出一个输出流，
 * 以及需要手动绑定输入流 {@link bindIncomeStream}
 */
class ReadableStreamIpc(
    override val remote: MicroModule,
    override val role: IPC_ROLE,
) : Ipc() {
    private lateinit var controller: ReadableStream.ReadableStreamController

    val stream = ReadableStream(onStart = {
        controller = it
    }, onPull = { (size, controller) ->
        debugStream("IPC-ON-PULL/${controller.stream}", size)
    })

    @Synchronized
    private suspend inline fun enqueue(data: ByteArray) = controller.enqueue(data)


    private var _incomeStream: InputStream? = null

    /**
     * 输入流要额外绑定
     */
    fun bindIncomeStream(stream: InputStream, coroutineName: String) {
        if (this._incomeStream !== null) {
            throw Exception("in come stream already binded.");
        }
        if (supportMessagePack) {
            throw Exception("还未实现 MessagePack 的编解码能力")
        }

        val j = GlobalScope.launch {
            while (true) {
                delay(10000)
                debugStreamIpc("LIVE/$stream")
            }
        }
        _incomeStream = stream
        CoroutineScope(CoroutineName(coroutineName) + Dispatchers.IO + CoroutineExceptionHandler { ctx, e ->
            printerrln("$ctx/$stream", e.message, e)
        }).launch {

            // 如果通道关闭并且没有剩余字节可供读取，则返回 true
            while (stream.available() > 0) {
                val size = stream.readInt()
                if (size <= 0) { // 心跳包？
                    continue
                }
                // 读取指定数量的字节并从中生成字节数据包。 如果通道已关闭且没有足够的可用字节，则失败
                val chunk = stream.readByteArray(size).toString(Charsets.UTF_8)
                debugStreamIpc("size/$stream", size)

                val message =
                    jsonToIpcMessage(chunk, this@ReadableStreamIpc)
                when (message) {
                    "close" -> close()
                    is IpcMessage -> _messageSignal.emit(
                        IpcMessageArgs(
                            message,
                            this@ReadableStreamIpc
                        )
                    )
                    else -> throw Exception("unknown message: $message")
                }
            }
            j.cancel()
            debugStreamIpc("END/$stream")
        }
    }

    override suspend fun _doPostMessage(data: IpcMessage) {
        val message = when {
            supportMessagePack -> moshiPack.packToByteArray(data)
            else -> when (data) {
                is IpcRequest -> gson.toJson(data.ipcReqMessage).asUtf8()
                is IpcResponse -> gson.toJson(data.ipcResMessage).asUtf8()
                else -> gson.toJson(data).asUtf8()
            }
        }
        debugStreamIpc("post/$stream", message.size)
        enqueue(message.size.toByteArray() + message)
    }

    override suspend fun _doClose() {
        controller.close()
    }
}
