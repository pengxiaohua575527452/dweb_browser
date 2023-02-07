//
//  DwebDNS.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/30.
//

import Foundation

class DnsNMM: NativeMicroModule {
    static let shared = DnsNMM()
    
    var apps: [MMID: MicroModule] = [:]
    
    private var bootNMM = BootNMM(mmid: "boot.sys.dweb")
    private var multiWebViewNMM = MultiWebViewNMM(mmid: "mwebview.sys.dweb")
    var jsProcessNMM = JsProcessNMM()
    override init(mmid:MMID = "dns.sys.dweb") {
        super.init(mmid:mmid)
        self.install(mm: bootNMM)
        self.install(mm: multiWebViewNMM)
        self.install(mm: jsProcessNMM)
        print(apps)
        
        // 注册桌面
        let desktopJmm = NativeMicroModule(mmid: "desktop.sys.dweb")
        print("desktopJmm")
        self.install(mm: desktopJmm)
    }
    
//    private var Routers: [String:(Any) -> Any] = [:]
    override func _bootstrap() -> Any {
        install(mm: self)
        running_apps[mmid] = self
        
        Routers["/install-js"] = { _ in
            return
        }
        Routers["/open"] = { args in
            guard let args = args as? [String:MMID] else { return false }
            
            if args["app_id"] != nil {
                self.open(mmid: args["app_id"]!)
            }

            return true
        }
        Routers["/close"] = { args in
            guard let args = args as? [String:MMID] else { return false }

            if args["app_id"] != nil {
                self.close(mmid: args["app_id"]!)
            }

            return true
        }
        
        return open(mmid: "boot.sys.dweb")
    }
    
    func query(mmid: MMID) -> MicroModule? {
        if apps.index(forKey: mmid) != nil {
            return apps[mmid]
        } else {
            return nil
        }
    }
    
    var running_apps: [MMID: MicroModule] = [:]
    func open(mmid: MMID) -> MicroModule? {
        var app: MicroModule
        if running_apps.index(forKey: mmid) != nil {
            app = running_apps[mmid]!
        } else {
            let mm = query(mmid: mmid)
            
            if mm == nil {
                print("no found app: \(mmid)")
                return nil
            }
            
            running_apps[mmid] = mm!
            mm!.bootstrap()
            app = mm!
        }
        
        return app
    }
    
    func _shutdown() {
        for mmid in running_apps.keys {
            let _ = close(mmid: mmid)
        }
    }
    
    func install(mm: MicroModule) {
        apps[mm.mmid] = mm
    }
    
    func close(mmid: MMID) -> Int {
        if running_apps.index(forKey: mmid) != nil {
            let app = running_apps[mmid]!
            app.shutdown()
            return 0
        } else {
            return -1
        }
    }
    
    private var connects: [MicroModule: [MMID:NativeIpc]] = [:]
    // 原生fetch
    func nativeFetch(urlString: String, microModule: MicroModule?) -> Any? {
        print(urlString)
        guard let url = URL(string: urlString) else { return nil }
        
        if url.scheme == nil {
            return nil
        }
        
        if url.host == nil {
            return nil
        }
        
        if url.scheme!.hasPrefix("file") && url.host!.hasSuffix(".dweb") {
            let pathnames = url.pathComponents
            let pathname = pathnames.joined(separator: "")
            
            var args: [String:Any] = [:]
            let hosts = url.host!.split(separator: ".")
            
            // 获取url get参数，
            args.merge(dict: url.urlParameters!)
            
            // 获取 microModule mmid
            let mmid: MMID
            if hosts.count > 3 {
                args["appKey"] = hosts.first
                mmid = hosts[hosts.count-3..<hosts.count].joined(separator: ".")
            } else {
                mmid = url.host!
            }
            
            if microModule != nil {
                var from_app_ipcs = connects[microModule!]
                if from_app_ipcs == nil {
                    from_app_ipcs = [:]
                    connects[microModule!] = from_app_ipcs
                }
                
                let ipc = from_app_ipcs![mmid]
                if ipc == nil {
                    do {
                        let app = self.open(mmid: mmid)
                        if let app = app as? JsMicroModule {
                            let ipc = try app.connect(from: microModule!)
                            ipc?.onClose {
//                                from_app_ipcs?.removeValue(forKey: mmid)!
                                self.connects[microModule!]?.removeValue(forKey: mmid)
                            }
                            from_app_ipcs![mmid] = ipc as? JsIpc
                            connects[microModule!] = from_app_ipcs
                        } else {
                            let ipc = try app?.connect(from: microModule!)
                            ipc?.onClose {
//                                from_app_ipcs?.removeValue(forKey: mmid)!
                                self.connects[microModule!]?.removeValue(forKey: mmid)
                            }
                            from_app_ipcs![mmid] = ipc as? NativeIpc
                            connects[microModule!] = from_app_ipcs
                        }
                    } catch {
    //                    throw MicroModuleError.moduleError("DnsNMM nativeFetch error: \(error)")
                        print("DnsNMM nativeFetch error: \(error)")
                    }
                }
            }
            print(connects)
            
            guard let mm = DnsNMM.shared.apps[mmid] as? NativeMicroModule else { return nil }
            
            for key in mm.Routers.keys {
                if pathname.hasPrefix(key) {
                    mm._initCommonIpcOnMessage()
                    return mm.Routers[key]!(args)
                }
            }
        }
        
        return nil
    }
}
