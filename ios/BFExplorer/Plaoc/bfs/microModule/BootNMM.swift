//
//  BootNMM.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/31.
//

class BootNMM: NativeMicroModule {
    var registeredMmids: Set<String> = ["desktop.sys.dweb", "http.sys.dweb"]
    
//    private var Routers: [String:(Any) -> Any] = [:]
    override func _bootstrap() -> Any {
        for mmid in registeredMmids {
            DnsNMM.shared.nativeFetch(urlString: "file://dns.sys.dweb/open?app_id=\(mmid)", microModule: self)
        }
        
        return true
    }
    
    convenience init() {
        self.init(mmid: "boot.sys.dweb")
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
