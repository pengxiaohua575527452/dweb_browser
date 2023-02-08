//
//  JsMicroModule.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/31.
//

import Foundation

struct Metadata {
    var main_url: String
}

/** 可动态加载的微组件 */
class JsMicroModule: MicroModule {
    var metadata: Metadata
    var process_id: Int?

    override func _bootstrap() -> Any {
        do {
            var url: URL?
            if self.metadata.main_url.hasPrefix("http") {
                url = URL(string: self.metadata.main_url)
            } else {
                url = URL(fileURLWithPath: Bundle.main.bundlePath + self.metadata.main_url)
            }
            
            if url == nil {
                return false
            }
            
            let content = try String(contentsOf: url!, encoding: .utf8)
            process_id = DnsNMM.shared.nativeFetch(urlString: "file://js.sys.dweb/create-process?main_code=\(content.encodeURIComponent())", microModule: self) as? Int
            print("JsMicroModule process_id: \(process_id!)")
        } catch {
            print("JsMicroModule url parse content error: \(error)")
        }
        
        return true
    }
    
    override func _connect(from: MicroModule) throws -> JsIpc {
        if process_id == nil {
            print("process_id no found")
            throw MicroModuleError.moduleError("module \(from.mmid) process_id no found")
        }
        
        let _ = DnsNMM.shared.nativeFetch(urlString: "file://js.sys.dweb/create-ipc?process_id=\(process_id!)", microModule: self)
        let ipc = JsIpc(port1: "\(process_id!)_port2", port2: "\(process_id!)_port1")
        return ipc
    }
    
    init(mmid: MMID, metadata: Metadata) {
        self.metadata = metadata
        super.init()
        self.mmid = mmid
    }
}

