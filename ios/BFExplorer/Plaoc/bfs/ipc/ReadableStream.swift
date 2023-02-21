//
//  ReadableStreamIpc.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/21.
//

import Foundation
import Combine

class ReadableStream: InputStream {
    private let dataChannel = PassthroughSubject<Data, Never>()
    private let controlSignal = Signal<(StreamControlSignal)>()
    private lazy var controller = ReadableStreamController(dataChannel)
    
    enum StreamControlSignal {
        case PULL
    }
    
    class ReadableStreamController {
        private let dataChannel: PassthroughSubject<Data, Never>
        private var cancellable: AnyCancellable?
        
        init(_ dataCannel: PassthroughSubject<Data, Never>) {
            self.dataChannel = dataCannel
            
        }
        
        func enqueue(_ data: Data) {
            dataChannel.send(data)
        }
        
        func close() {
//            dataChannel
        }
        
        func error() {
            
        }
    }
    
    init(onStart: ((ReadableStreamController)) -> Any?, onPull: ((ReadableStreamController)) -> Any?) {
        _ = onStart(controller)
        
        _ = controlSignal.listen { signal in
            switch signal {
            case .PULL:
                Task {
                    onPull(self.controller)
                }
            }
        }
        
        Task {
            dataChannel.sink(receiveCompletion: { complete in
                switch complete {
                case .finished:
                    self.closed = true
                    self.closeLock.signal()
                }
            }, receiveValue: { value in
                
            })
        }
    }
    
    private var closeLock = DispatchSemaphore(value: -1)
    private var closed = false
    private var dataLock = DispatchSemaphore(value: 0)
    
    func doclosed() {
        if closed { return }
        
        closeLock.wait()
        
    }
    
    
    private func requestData(ptr: Int) -> Data {
//        if ptr < _
        
    }
    
    private var _data: Data = Data()
    private var ptr = 0
    private var mark = 0
}
