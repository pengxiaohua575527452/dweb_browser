//
//  MultiWebViewNMM.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/31.
//

import UIKit
import Foundation

class MultiWebViewNMM: NativeMicroModule {
    static var shared = MultiWebViewNMM()
    override var mmid: MMID {
        get {
            "mwebview.sys.dweb"
        }
        set {
            "mwebview.sys.dweb"
        }
    }

    var viewTree: ViewTree?
//    var Routers: [String:(Any) -> Any] = [:]
    
    override init() {
        super.init()
        Routers["/open"] = { args in
            guard let args = args as? [String:Any] else { return false }
            guard let url = args["url"] as? String else { return false }
            
            if url == "desktop.html" {
                guard let app = UIApplication.shared.delegate as? AppDelegate else { return false }
                
                app.window = UIWindow(frame: UIScreen.main.bounds)
                app.window?.makeKeyAndVisible()
                app.window?.rootViewController = UINavigationController(rootViewController: BrowserContainerViewController())
                return true
            } else {
                return self.open(args: args)
            }
        }
    }
    
    private func open(args: WindowOptions) -> Int {
        let webview = WebViewViewController()
        let name = args["name"] as! String
        webview.appId = name
        webview.urlString = sharedInnerAppFileMgr.systemWebAPPURLString(appId: name)! //"iosqmkkx:/index.html"
        webview.urlString = args["url"] as! String

        let webviewNode = viewTree!.createNode(webview: webview, args: args)
        viewTree!.appendTo(webviewNode: webviewNode)

        NotificationCenter.default.post(name: openAnAppNotification, object: webview)
        return webviewNode.id
    }

    private func evalJavascript(code: String) -> String {
        return ""
    }

    private func listen() -> String {
        return ""
    }

    private func request() -> String {
        return ""
    }

    private func response(res: IpcResponse) -> Void {
        return
    }
}
