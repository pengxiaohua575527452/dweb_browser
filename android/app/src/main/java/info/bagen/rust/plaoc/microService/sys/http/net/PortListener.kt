package info.bagen.rust.plaoc.microService.sys.http.net

import com.google.gson.*
import info.bagen.rust.plaoc.microService.helper.SimpleCallback
import info.bagen.rust.plaoc.microService.helper.SimpleSignal
import info.bagen.rust.plaoc.microService.ipc.Ipc
import info.bagen.rust.plaoc.microService.ipc.IpcMethod
import info.bagen.rust.plaoc.microService.ipc.ipcWeb.ReadableStreamIpc
import org.http4k.core.Method
import org.http4k.core.Request
import org.http4k.core.Response
import java.lang.reflect.Type


data class RouteConfig(
    val pathname: String,
    val method: IpcMethod,
    val matchMode: MatchMode = MatchMode.PREFIX
)

class StreamIpcRouter(val config: RouteConfig, val streamIpc: ReadableStreamIpc) {

    val isMatch: (request: Request) -> Boolean by lazy {
        when (config.matchMode) {
            MatchMode.PREFIX -> { request ->
                request.method == config.method.http4kMethod && request.uri.path.startsWith(
                    config.pathname
                )
            }
            MatchMode.FULL -> { request ->
                request.method == config.method.http4kMethod && request.uri.path == config.pathname
            }
        }
    }

    suspend fun handler(request: Request) = if (isMatch(request)) {
        streamIpc.request(request)
    } else null
}


class PortListener(
    val ipc: Ipc,
    val host: String
) {
    private val _routerSet = mutableSetOf<StreamIpcRouter>();

    fun addRouter(config: RouteConfig, streamIpc: ReadableStreamIpc): (Unit) -> Boolean {
        val route = StreamIpcRouter(config, streamIpc);
        this._routerSet.add(route)
        return {
            this._routerSet.remove(route)
        }
    }

    /**
     * 接收 nodejs-web 请求
     * 将之转发给 IPC 处理，等待远端处理完成再代理响应回去
     */
    suspend fun hookHttpRequest(request: Request): Response? {
        for (router in _routerSet) {
            val response = router.handler(request)
            if (response != null) {
                return response
            }
        }
        return null
    }

    /// 销毁
    private val destroySignal = SimpleSignal()
    fun onDestroy(cb: SimpleCallback) = destroySignal.listen { cb }

    suspend fun destroy() {
        _routerSet.clear()
        destroySignal.emit()
    }
}


interface ReqMatcher {
    val pathname: String;
    val matchMode: MatchMode
    var method: Method?
}

fun isMatchReq(
    matcher: Request,
    pathname: String,
    method: Method = Method.GET
): Boolean {
    val matchMethod = if (matcher.method == method) {
        matcher.method(method)
        true
    } else {
        false
    }
    println("PortListener#isMatchReq===>${matcher.equals("full")},${matcher.uri.path} ")
    val matchMode = if (matcher.equals("full")) {
        pathname == matcher.uri.path
    } else {
        if (matcher.equals("prefix")) {
            pathname.startsWith(matcher.uri.path)
        } else {
            false
        }
    }
    return matchMethod && matchMode
};

enum class MatchMode(val mode: String) : JsonDeserializer<MatchMode>, JsonSerializer<MatchMode> {
    FULL("full"),
    PREFIX("prefix"),
    ;

    override fun deserialize(
        json: JsonElement,
        typeOfT: Type?,
        context: JsonDeserializationContext?
    ) = json.asString.let { mode -> values().first { it.mode == mode } }

    override fun serialize(
        src: MatchMode,
        typeOfSrc: Type?,
        context: JsonSerializationContext?
    ) = JsonPrimitive(src.mode)
}