//
//  HTTPServerManager.swift
//  BFExplorer
//
//  Created by ui03 on 2023/2/9.
//

import Foundation
import NIO
import NIOHTTP1
import NIOPosix

let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
final class HttpServer: Router {
    
    private func createServerBootstrap() -> ServerBootstrap {
        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)
        
        
        let bootstrap = ServerBootstrap(group: loopGroup)
                .serverChannelOption(reuseAddrOpt, value: 1)
                .childChannelInitializer { channel in
                    return channel.pipeline.configureHTTPServerPipeline().flatMap { _ in
                        channel.pipeline.addHandler(HTTPHandler(router: self))
                    }
                }
                .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
                .childChannelOption(reuseAddrOpt, value: 1)
                .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
        
        return bootstrap
    }
    
    func listen(_ port: Int, _ host: String = "localhost") {
        let bootstrap = self.createServerBootstrap()
        
        do {
            let serverChannel = try bootstrap.bind(host: host, port: port).wait()
            
            print("server running on: ", serverChannel.localAddress!)
            
            // runs forever
//            try serverChannel.closeFuture.wait()
        } catch {
            fatalError("failed to start server: \(error)")
        }
    }
    
    func listen(_ port: Int, _ host: String = "localhost", _ listeningListener: (() -> Void)?) {
        let bootstrap = self.createServerBootstrap()
        
        do {
            let serverChannel = try bootstrap.bind(host: host, port: port).wait()
            
            if listeningListener != nil {
                listeningListener!()
            }
            
//            try serverChannel.closeFuture.wait()
        } catch {
            fatalError("failed to start server: \(error)")
        }
    }
    
    func listen(unixSocket: String = "bfs.socket") {
        let bootstrap = self.createServerBootstrap()
        
        do {
            let serverChannel = try bootstrap.bind(unixDomainSocketPath: unixSocket).wait()
            
            // runs forever
//            try serverChannel.closeFuture.wait()
        } catch {
            fatalError("failed to start server: \(error)")
        }
    }
    
    final class HTTPHandler : ChannelInboundHandler {
        typealias InboundIn = HTTPServerRequestPart
        
        let router : Router
        
        init(router: Router) {
            self.router = router
        }
        
        private var req: IncomingMessage?
        private var buffer: ByteBuffer! = nil

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let reqPart = self.unwrapInboundIn(data)
            print("channelRead")
          
            switch reqPart {
            case .head(let header):
                print("reqPart head")
                req = IncomingMessage(header: header)
            case .body(let body):
                print("reqPart body")
                print(body)
                if req != nil {
                    var part = body
                    buffer.writeBuffer(&part)
                }
            case .end:
                print("reqPart end")
                let res = ServerResponse(channel: context.channel)
                
                if req != nil {
                    req!.setBody(body: buffer)
                    router.handle(request: req!, response: res) { (items : Any...) in // the final handler
                        res.status = .notFound
                        res.send("No middleware handled the request!")
                    }
                }
            }
        }
        
        func errorCaught(context: ChannelHandlerContext, error: Error) {
            print("socket error, closing connection:", error)
            context.close(promise: nil)
        }
    }
}




