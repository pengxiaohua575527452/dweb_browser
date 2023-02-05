//
//  MicroModule.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/2/1.
//

import Foundation

/** 微组件抽象类 */
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

    internal func before_bootstrap() throws {
        if running {
            throw MicroModuleError.moduleError("module \(mmid) already running")
        }
        running = true
    }

    internal func _bootstrap() -> Any {
        return ""
    }
    internal func after_bootstrap() {}

    func bootstrap() {
        do {
            try before_bootstrap()

            let _ = _bootstrap()

            after_bootstrap()
        } catch {
            print(error)
        }
    }

    internal func before_shutdown() throws {
        if !running {
            throw MicroModuleError.moduleError("module \(mmid) already shutdown")
        }
        running = false
    }
    internal func _shutdown() -> Any {
        return ""
    }
    internal func after_shutdown() {}
    func shutdown() -> Void {
        do {
            try before_shutdown()

            let _ = _shutdown()

            after_shutdown()
        } catch {
            print(error)
        }
    }

    func _connect(from: MicroModule) -> NativeIpc {
        return NativeIpc(port1: "port1", port2: "port2")
    }
    func connect(from: MicroModule) throws -> NativeIpc? {
        if !running {
            throw MicroModuleError.moduleError("module no running")
        }
        return _connect(from: from)
    }
}
