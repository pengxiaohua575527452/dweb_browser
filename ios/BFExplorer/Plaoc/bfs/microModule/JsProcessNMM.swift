//
//  JsProcessNMM.swift
//  BFExplorer
//
//  Created by ui08 on 2023/2/2.
//

import WebKit
import SwiftyJSON
import Foundation

class JsProcessNMM: NativeMicroModule {
    override var mmid: MMID {
        get {
            "js.sys.dweb"
        }
        set {
            "js.sys.dweb"
        }
    }
    
    private lazy var webview: WKWebView = {
        let config = WKWebViewConfiguration()
        
        config.userContentController = WKUserContentController()
        let data = try? Data(contentsOf: URL(fileURLWithPath: Bundle.main.bundlePath + "/app/injectWebView/console.js"))
        if data != nil {
            if let jsString = String(data: data!, encoding: .utf8) {
                let script = WKUserScript(source: jsString, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                config.userContentController.addUserScript(script)
            }
        }
        
        config.userContentController.add(LeadScriptHandle(messageHandle: self), name: "webworkerOnmessage")
        config.userContentController.add(LeadScriptHandle(messageHandle: self), name: "logging")
        let webview = WKWebView(frame: .zero, configuration: config)
        return webview
    }()
    
    private var acc_process_id = 0
    override init() {
        super.init()
        _ = webview
        
        Routers["/create-process"] = { args in
            guard let args = args as? [String:String] else { return false }
            
            if args["main_code"] == nil {
                return nil
            }
            
            let timestamp = Date().milliStamp
            self.hookJavascriptWorker(timestamp: timestamp, main_code: args["main_code"]!)
            
            self.acc_process_id = timestamp
            return timestamp
        }
        Routers["/create-ipc"] = { args in
            return
        }
    }
    
    func hookJavascriptWorker(timestamp: Int, main_code: String) {
            DispatchQueue.global().async {
                do {
                    let injectWorkerDir = URL(fileURLWithPath: Bundle.main.bundlePath + "/app/injectWebView/worker.js")
//                    let injectWorkerDir = URL(string: "https://objectjson.waterbang.top/js-process.worker.js?v=\(Date().milliStamp)")!
                    
                    let injectWorkerCode = try String(contentsOf: injectWorkerDir, encoding: .utf8)
                    let workerCode = """
                        data:utf-8,
                     ((module,exports=module.exports)=>{\(injectWorkerCode.encodeURIComponent());return module.exports})({exports:{}}).installEnv();
                     \(main_code)
                    """.replacingOccurrences(of: "use strict", with: "")
                    
                    DispatchQueue.main.async {
                        let text = """
                            window.webkit.messageHandlers.logging.postMessage('xxxxxxxx')
                            try {
                                globalThis.logging = window.webkit.messageHandlers.logging
                                let webworker_\(timestamp) = new Worker(`\(workerCode)`)
                                webworker_\(timestamp).onmessage = (event) => {
                                    window.webkit.messageHandlers.logging.postMessage('webworker ... onmessage start');
                                    
                                    if(Array.isArray(event.data) && event.data[0] === 'fetch-ipc-channel') {
                                        let port2 = event.data[1]
                                        port2.onmessage = (evt) => {
                                            window.webkit.messageHandlers.webworkerOnmessage.postMessage(JSON.stringify(evt.data))
                                        }
                                    }
                                    window.webkit.messageHandlers.logging.postMessage('webworker ... onmessage end');
                                }
                                window.webkit.messageHandlers.logging.postMessage('xxxxxxxx');
                            } catch(e) {
                                window.webkit.messageHandlers.logging.postMessage('error');
                                window.webkit.messageHandlers.logging.postMessage(e.message);
                            }
                            '111'
                        """
                        self.webview.evaluateJavaScript(text) {(result, error) in
                            if error != nil {
                                print(error.debugDescription)
                            }
                        }
                    }
                } catch {
                    print("JsProcessNMM hookJavascriptWorker error: \(error)")
                }
            }
            
        
    }
}

extension JsProcessNMM: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if message.name == "webworkerOnmessage" {
            guard let body = message.body as? String else { return }
            let args = JSON.init(parseJSON: body)
            let url = args["url"].stringValue
            let result = DnsNMM.shared.nativeFetch(urlString: url)
        } else if(message.name == "logging") {
            print(message.body)
        }
    }
}
