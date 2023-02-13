//
//  MultiWebViewNMM.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/31.
//

import UIKit
import Foundation

class MultiWebViewNMM: NativeMicroModule {
    var viewTree: ViewTree = ViewTree()
//    var Routers: [String:(Any) -> Any] = [:]
    
    convenience init() {
        self.init(mmid: "mwebview.sys.dweb")
        Routers["/open"] = { args in
            guard let args = args as? [String:Any] else { return false }
            
            return self.open(args: args)
        }
    }
    
    private func open(args: WindowOptions) -> Int {
        let webview = WebViewViewController()
        webview.urlString = args["url"] as! String

        let webviewNode = viewTree.createNode(webview: webview, args: args)
        viewTree.appendTo(webviewNode: webviewNode)

        NotificationCenter.default.post(name: openAnAppNotification, object: webview)
        print("id: \(webviewNode.id)")
        
        return webviewNode.id
    }
    
    override func _shutdown() -> Any {
        return true
    }
}
