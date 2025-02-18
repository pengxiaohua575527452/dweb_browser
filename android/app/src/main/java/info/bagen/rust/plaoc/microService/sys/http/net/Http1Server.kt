package info.bagen.rust.plaoc.microService.sys.http.net

import info.bagen.rust.plaoc.microService.helper.PromiseOut
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.http4k.core.HttpHandler
import org.http4k.server.Http4kServer
import org.http4k.server.KtorCIO
import org.http4k.server.asServer


class Http1Server {
    companion object {
        const val PREFIX = "http://";
        const val PROTOCOL = "http:";
        const val PORT = 80;
    }

    var bindingPort = -1

    private var server: Http4kServer? = null
    suspend fun createServer(handler: HttpHandler) {
        if (server != null) {
            throw Exception("server alter created")
        }

        val portPo = PromiseOut<Int>()
        CoroutineScope(Dispatchers.IO).launch {
            server = handler.asServer(KtorCIO(22206/* 使用随机端口*/)).start().also { server ->
                bindingPort = server.port()
                portPo.resolve(bindingPort)
            }
        }
        portPo.waitPromise()
    }

    val authority get() = "localhost:$bindingPort"
    val origin get() = "$PREFIX$authority"

    fun closeServer() {
        server?.also {
            it.close()
            server = null
        } ?: throw Exception("server not created")
    }
}


