//
//  Fs.swift
//  BFExplorer
//
//  Created by biyou on 2023/2/10.
//

import Foundation

import NIO

enum fs {
    static let threadPool : NIOThreadPool = {
        let tp = NIOThreadPool(numberOfThreads: 4)
        tp.start()
        return tp
    }()

    static let fileIO = NonBlockingFileIO(threadPool: threadPool)

    static func readFile(_ path    : String,
                eventLoop : EventLoop? = nil,
                maxSize   : Int = 1024 * 1024,
                 _ cb: @escaping ( Error?, ByteBuffer? ) -> ())
    {
        let eventLoop = eventLoop
                 ?? MultiThreadedEventLoopGroup.currentEventLoop
                 ?? loopGroup.next()
    
        func emit(error: Error? = nil, result: ByteBuffer? = nil) {
            if eventLoop.inEventLoop { cb(error, result) }
            else { eventLoop.execute { cb(error, result) }  }
        }
    
        threadPool.submit {
            assert($0 == .active, "unexpected cancellation")
          
            let fh : NIO.NIOFileHandle
            do { // Blocking:
              fh = try NIO.NIOFileHandle(path: path)
            } catch { return emit(error: error) }
          
            fileIO.read(fileHandle: fh, byteCount: maxSize, allocator: ByteBufferAllocator(), eventLoop: eventLoop)
                  .map { try? fh.close(); emit(result: $0) }
                  .whenFailure { try? fh.close(); emit(error:  $0) }
        }
    }
}
