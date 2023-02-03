//
//  MicroModule.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/2/1.
//

import Foundation

/** 微组件抽象类 */
//protocol MicroModule {
//    var mmid: String { get }
//    var ipc: Ipc { get }
//
//    func bootstrap()
//}

typealias MMID = String

class MicroModule: NSObject {
    var mmid: MMID {
        get {
            ".dweb"
        }
        set {
            ".dweb"
        }
    }
    var running = false

    func before_bootstrap() {
        if running {
            print("module \(mmid) already running")
            return
        }
        running = true
    }

    func _bootstrap() -> Any {
        return ""
    }
    func after_bootstrap() {}

    func bootstrap() {
        before_bootstrap()

        let _ = _bootstrap()

        after_bootstrap()
    }

    func before_shutdown() {
        if !running {
            print("module \(mmid) already shutdown")
            return
        }
        running = false
    }
    internal func _shutdown() -> Any {
        return ""
    }
    func after_shutdown() {}
    func shutdown() -> Void {
        before_shutdown()

        let _ = _shutdown()

        after_shutdown()
    }

    func _connect(from: MicroModule) -> Ipc {
        return Ipc()
    }
    func connect(from: MicroModule) -> Ipc? {
        if !running {
            print("module no running")
            return nil
        }
        return _connect(from: from)
    }
}
