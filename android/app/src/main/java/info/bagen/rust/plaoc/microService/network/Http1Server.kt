package info.bagen.rust.plaoc.microService.network

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.http4k.core.*
import org.http4k.server.Http4kServer
import org.http4k.server.Netty
import org.http4k.server.asServer



class Http1Server {
    companion object {
        const val PREFIX = "http://";
        const val PROTOCOL = "http:";
        const val PORT = 80;
    }

    private var bindingPort = 24433

    private var server: Http4kServer? = null
    fun createServer(setContentType:  Filter) {
        if (server != null) {
            throw Exception("server alter created")
        }
        val app = { request: Request -> Response(Status.OK).body("Hello, ${request.query("name")}!") }

        CoroutineScope(Dispatchers.IO).launch {
            setContentType(app).asServer(Netty(bindingPort)).start()
        }
    }

    fun closeServer() {
        server?.also {
            it.close()
            server = null
        } ?: throw Exception("server not created")
    }
}


