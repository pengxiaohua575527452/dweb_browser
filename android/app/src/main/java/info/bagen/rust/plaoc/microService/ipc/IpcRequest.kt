package info.bagen.rust.plaoc.microService.ipc

import info.bagen.rust.plaoc.microService.helper.toBase64
import org.http4k.core.Request
import org.http4k.core.Uri
import java.io.InputStream

class IpcRequest(
    val req_id: Int,
    val ipcMethod: IpcMethod,
    val url: String,
    val headers: IpcHeaders,
    rawBody: RawData,
    ipc: Ipc
) : IpcBody(IPC_DATA_TYPE.REQUEST, rawBody, ipc) {
    val uri by lazy { Uri.of(url) }

    companion object {

        fun fromRequest(req_id: Int, request: Request, ipc: Ipc) = when (request.body.length) {
            null -> fromStream(
                req_id,
                IpcMethod.from(request.method),
                request.uri.toString(),
                IpcHeaders(request.headers),
                request.body.stream,
                ipc
            )
            0L -> {
                fromText(
                    req_id,
                    IpcMethod.from(request.method),
                    request.uri.toString(),
                    IpcHeaders(request.headers),
                    "",
                    ipc,
                )
            }
            else -> fromBinary(
                req_id,
                IpcMethod.from(request.method),
                request.uri.toString(),
                IpcHeaders(request.headers),
                request.body.payload.array(),
                ipc
            )
        }


        fun fromText(
            req_id: Int,
            ipcMethod: IpcMethod,
            url: String,
            headers: IpcHeaders = IpcHeaders(),
            rawBody: String,
            ipc: Ipc
        ) = IpcRequest(
            req_id, ipcMethod, url,
            // 这里 content-length 默认不写，因为这是要算二进制的长度，我们这里只有在字符串的长度，不是一个东西
            headers, RawData(IPC_RAW_BODY_TYPE.TEXT, rawBody), ipc
        );

        fun fromBinary(
            req_id: Int,
            ipcMethod: IpcMethod,
            url: String,
            headers: IpcHeaders = IpcHeaders(),
            binary: ByteArray,
            ipc: Ipc
        ) = IpcRequest(
            req_id, ipcMethod, url,
            // 这里 content-length 默认不写，因为这是要算二进制的长度，我们这里只有在字符串的长度，不是一个东西
            headers.also {
                headers.init("Content-Type", "application/octet-stream");
                headers.init("Content-Length", binary.size.toString());
            }, if (ipc.supportBinary) RawData(IPC_RAW_BODY_TYPE.BINARY, binary)
            else RawData(
                IPC_RAW_BODY_TYPE.BASE64, binary.toBase64()
            ), ipc
        )

        fun fromStream(
            req_id: Int,
            ipcMethod: IpcMethod,
            url: String,
            headers: IpcHeaders = IpcHeaders(),
            stream: InputStream,
            ipc: Ipc,
            size: Long? = null
        ) = IpcRequest(
            req_id, ipcMethod, url,
            // 这里 content-length 默认不写，因为这是要算二进制的长度，我们这里只有在字符串的长度，不是一个东西
            headers.also {
                headers.init("Content-Type", "application/octet-stream");
                if (size !== null) {
                    headers.init("Content-Length", size.toString());
                }
            },
            streamAsRawData(stream, ipc),
            ipc
        )

    }

    fun asRequest() = Request(ipcMethod.http4kMethod, url).headers(headers.toList()).let { req ->
        when (val body = body) {
            is String -> req.body(body)
            is ByteArray -> req.body(body.inputStream(), body.size.toLong())
            is InputStream -> req.body(body)
            else -> throw Exception("invalid body to request: $body")
        }
    }

    val data by lazy {
        IpcRequestData(req_id, ipcMethod, url, headers, rawBody)
    }
}

class IpcRequestData(
    val req_id: Int,
    val ipcMethod: IpcMethod,
    val url: String,
    val headers: IpcHeaders,
    val rawBody: RawData,
) : IpcMessage(IPC_DATA_TYPE.REQUEST)
