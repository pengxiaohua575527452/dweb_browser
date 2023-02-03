//
//  BootNMM.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/31.
//

import UIKit

class BootNMM: NativeMicroModule {
    override var mmid: MMID {
        get {
            "boot.sys.dweb"
        }
        set {
            "boot.sys.dweb"
        }
    }
    
    var registeredMmids: Set<String> = ["desktop.sys.dweb"]
    
//    private var Routers: [String:(Any) -> Any] = [:]
    override func _bootstrap() -> Any {
        for mmid in registeredMmids {
            DnsNMM.shared.nativeFetch(urlString: "file://dns.sys.dweb/open?app_id=\(mmid)")
        }
        
        return true
    }
    
    override init() {
        super.init()
        
        Routers["/register"] = { args in
            guard let args = args as? [String:MMID] else { return false }
            
            if args["app_id"] != nil {
                self.register(mmid: args["app_id"]!)
            }
            
            return true
        }
        Routers["/unregister"] = { args in
            guard let args = args as? [String:MMID] else { return false }
            
            if args["app_id"] != nil {
                self.unregister(mmid: args["app_id"]!)
            }
            
            return true
        }
    }
    
    private func register(mmid: String) -> Bool {
        registeredMmids.insert(mmid)
        return true
    }

    private func unregister(mmid: String) -> Bool {
        if registeredMmids.contains(mmid) {
            registeredMmids.remove(mmid)
        }

        return true
    }
}
