//
//  CreateSignal.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/8.
//

import Foundation

/** 控制器 */
enum SIGNAL_CTOR {
    /**
     * 返回该值，会解除监听
     */
    case OFF
    /**
     * 返回该值，会让接下来的其它监听函数不再触发
     */
    case BREAK
}

class Signal<T> {
    typealias SignalClosure = (T) -> SIGNAL_CTOR?
    typealias OffListener = () -> Bool
    
    private var _cbs: Set<GenericsClosure<SignalClosure>> = []

    func listen(_ cb: @escaping SignalClosure) -> OffListener {
        let closureObj = GenericsClosure(closure: cb)
        self._cbs.insert(closureObj)
        
        return {
            self.off(closureObj)
        }
    }
    
    func off(_ closureObj: GenericsClosure<SignalClosure>) -> Bool {
        return (_cbs.remove(closureObj) != nil)
    }
    
    func emit(_ args: T) {
        for obj in _cbs {
            switch obj.closure(args) {
            case .OFF:
                _cbs.remove(obj)
            case .BREAK:
                break
            case .none:
                continue
            }
        }
    }
}



