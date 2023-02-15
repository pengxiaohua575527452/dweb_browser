package info.bagen.rust.plaoc.microService.route


import info.bagen.rust.plaoc.microService.global_dns
import info.bagen.rust.plaoc.microService.network.DefaultErrorResponse
import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*

fun Route.webViewRoute() {
    get("/open") {
        val origin: String? =
            call.request.queryParameters["origin"] ?: call.request.queryParameters["url"]
        val processId: String? =
            call.request.queryParameters["processId"] ?: call.request.queryParameters["process_id"]
        if (origin.isNullOrEmpty()) {
            return@get call.respond(
                DefaultErrorResponse(
                    statusCode = 403,
                    errorMessage = "not found request param origin or url"
                )
            )
        }
        println("webViewRoute#open origin: $origin ,processId:$processId")
        call.respondText(global_dns.multiWebViewNMM.openDwebView(origin,processId).toString())
    }
}