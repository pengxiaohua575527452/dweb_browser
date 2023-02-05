//
//  DwebDNS.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/30.
//

import Foundation

class DnsNMM: NativeMicroModule {
    static let shared = DnsNMM()
    override var mmid: MMID {
        get {
            "dns.sys.dweb"
        }
        set {
            "dns.sys.dweb"
        }
    }
    var apps: [MMID: MicroModule] = [:]
    
    override init() {
        super.init()
        self.install(mm: BootNMM())
        self.install(mm: MultiWebViewNMM())
        self.install(mm: JsProcessNMM())
        
        // 注册桌面
//        let desktopJmm = JsMicroModule(mmid: "desktop.sys.dweb", metadata: Metadata(main_url: "https://objectjson.waterbang.top/desktop.worker.js"))
        let desktopJmm = JsMicroModule(mmid: "desktop.sys.dweb", metadata: Metadata(main_url: "/app/injectWebView/desktop.worker.js"))
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
//        Routers["/open"] = { args in
//            guard let args = args as? [String:MMID] else { return false }
//            
//            if args["app_id"] != nil {
//                self.open(mmid: args["app_id"]!)
//            }
//            
//            return true
//        }
        Routers["/close"] = { args in
            guard let args = args as? [String:MMID] else { return false }
            
            if args["app_id"] != nil {
                self.close(mmid: args["app_id"]!)
            }
            
            return true
        }
        
        self.registerCommonIpcOnMessageHandler(commonHandlerSchema: RequestCommonHandlerSchema(pathname: "/open", matchMode: MatchMode.full, input: ["app_id":"mmid"], output: "boolean") { args, _ in
            guard let args = args as? [String:MMID] else { return false }
            
            if args["app_id"] != nil {
                self.open(mmid: args["app_id"]!)
            }
            
            return true
        })()
        
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
    
    // 原生fetch
    func nativeFetch(urlString: String) -> Any? {
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
            
            guard let mm = DnsNMM.shared.apps[mmid] as? NativeMicroModule else { return nil }
            
            for key in mm.Routers.keys {
                if pathname.hasPrefix(key) {
                    return mm.Routers[key]!(args)
                }
            }
        }
        
        return nil
    }
}
