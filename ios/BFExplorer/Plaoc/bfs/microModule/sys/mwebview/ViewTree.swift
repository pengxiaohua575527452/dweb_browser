//
//  ViewTree.swift
//  BFExplorer
//
//  Created by kingsword09 on 2023/1/30.
//

typealias WindowOptions = [String:Any]
struct WebviewNode {
    var id: Int
    var processId: Int?
    var args: WindowOptions?
    var webview: WebViewViewController?
}


class ViewTree {
    var root: WebviewNode
    var currentProcessId: Int
    
    private(set) var children: [WebviewNode] = []
    
    init() {
        root = WebviewNode(id: 0)
        currentProcessId = 0
        children.append(root)
    }

    func createNode(webview: WebViewViewController, args: WindowOptions) -> WebviewNode {
        let id = currentProcessId + 1
        let processId = currentProcessId
        let webviewNode: WebviewNode = WebviewNode(id: id, processId: processId, args: args, webview: webview)
        return webviewNode
    }

    func appendTo(webviewNode: WebviewNode) {
        children.append(webviewNode)
        currentProcessId = webviewNode.id
    }
}




