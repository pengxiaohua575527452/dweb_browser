//
//  CreateSignal.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

class Signal {
    typealias SignalClosure = (Any...) -> Any
    private var _cbs: Set<GenericsClosure<SignalClosure>> = []
    
    func listen(cb: @escaping SignalClosure) -> () -> Void {
        let closureObj = GenericsClosure(closure: cb)
        self._cbs.insert(closureObj)
        
        return {
//            self._cbs.remove(closureObj)
            return
        }
    }
    
    func emit(args: Any...) {
        for obj in self._cbs {
            obj.closure(args)
        }
    }
    
    static func createSignal() -> Signal {
        return Signal()
    }
}

class IpcSignal {
    typealias SignalClosure = OnIpcMessage
    private var _cbs: Set<GenericsClosure<SignalClosure>> = []
    
    func listen(cb: @escaping SignalClosure) -> () -> Void {
        let closureObj = GenericsClosure(closure: cb)
        self._cbs.insert(closureObj)
        
        return {
//            self._cbs.remove(closureObj)
            return
        }
    }
    
    func emit(message: IpcMessage, ipc: Ipc) {
        for obj in self._cbs {
            obj.closure(message, ipc)
        }
    }
    
    static func createSignal() -> IpcSignal {
        return IpcSignal()
    }
}

class IpcCloseSignal {
    typealias SignalClosure = () -> Any
    private var _cbs: Set<GenericsClosure<SignalClosure>> = []
    
    func listen(cb: @escaping SignalClosure) -> () -> Void {
        let closureObj = GenericsClosure(closure: cb)
        self._cbs.insert(closureObj)
        
        return {
//            self._cbs.remove(closureObj)
            return
        }
    }
    
    func emit() {
        for obj in self._cbs {
            obj.closure()
        }
    }
    
    static func createSignal() -> IpcCloseSignal {
        return IpcCloseSignal()
    }
}

