//
//  MultiWebViewNMM.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/31.
//

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
            guard let args = args as? [String:Any] else { return }
            NotificationCenter.default.post(name: NSNotification.Name.openDwebNotification, object: nil, userInfo: ["param":args["url"]])
            return
        }
        Routers["/evaluateJavascript"] = {_ in
            return
        }
    }
    
    private func open(args: WindowOptions) -> Int {
        let webview = WebViewViewController()
        let name = args["name"] as! String
        webview.appId = name
        webview.urlString = sharedInnerAppFileMgr.systemWebAPPURLString(appId: name)! //"iosqmkkx:/index.html"
        let type = sharedInnerAppFileMgr.systemAPPType(appId: name)
        let url = sharedInnerAppFileMgr.systemWebAPPURLString(appId: name) ?? ""
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
