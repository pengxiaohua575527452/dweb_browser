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
    override var mmid: MMID {
        get {
            return _mmid
        }
        set {
            _mmid = newValue
        }
    }
    var _mmid: MMID = ""
    var metadata: Metadata

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
            let process_id = DnsNMM.shared.nativeFetch(urlString: "file://js.sys.dweb/create-process?main_code=\(content.encodeURIComponent())")
            print("JsMicroModule process_id: \(process_id)")
        } catch {
            print("JsMicroModule url parse content error: \(error)")
        }
        
        return true
    }
    
    init(mmid: MMID, metadata: Metadata) {
        self.metadata = metadata
        super.init()
        self.mmid = mmid
    }
    
    
}

