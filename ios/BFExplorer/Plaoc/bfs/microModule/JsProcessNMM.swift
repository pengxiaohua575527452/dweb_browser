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
        config.userContentController.add(LeadScriptHandle(messageHandle: self), name: "portForward")
        let webview = WKWebView(frame: .zero, configuration: config)
        webview.evaluateJavaScript("const reqidPortMap = new Map(); const processPortMap = new Map();")
        return webview
    }()
    
    var all_ipc_cache: [Int:NativeIpc] = [:]
    
    private var acc_process_id = 0
    override init(mmid:MMID = "js.sys.dweb") {
        super.init(mmid:mmid)
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
            guard let args = args as? [String:Int], let process_id = args["worker_id"] as? Int else { return nil }
            
            if self.all_ipc_cache.index(forKey: process_id) == nil {
                print("JsProcessNMM create-ipc no found worker by id '\(process_id)'")
                return nil
            }
            
            DispatchQueue.main.async {
                self.webview.evaluateJavaScript("""
                    const port1 = processPortMap.get(\(process_id));
                    port1.onmessage = (evt) => {
                        evt.data['process_id'] = \(process_id);
                        window.webkit.messageHandlers.portForward.postMessage(evt.data);
                    }
                """)
            }
            
            return process_id
        }
    }
    
    func hookJavascriptWorker(timestamp: Int, main_code: String) {
        DispatchQueue.global().async {
            do {
                let injectWorkerDir = URL(fileURLWithPath: Bundle.main.bundlePath + "/app/injectWebView/worker.js")
                let injectWorkerCode = try String(contentsOf: injectWorkerDir, encoding: .utf8).replacingOccurrences(of: "\"use strict\";", with: "")
                let workerCode = """
                    data:utf-8,
                 ((module,exports=module.exports)=>{\(injectWorkerCode.encodeURIComponent());return module.exports})({exports:{}}).installEnv();
                 \(main_code)
                """
                
                DispatchQueue.main.async {
                    let text = """
                        window.webkit.messageHandlers.logging.postMessage('xxxxxxxx');
                        try {
                            let webworker_\(timestamp) = new Worker(`\(workerCode)`);
                            const {port1, port2} = new MessageChannel();
                            webworker_\(timestamp).postMessage(['fetch-ipc-channel', port2], [port2]);
                            processPortMap.set(\(timestamp), port1);
                        
                            port1.onmessage = (evt) => {
                                if(evt.data && Object.keys(evt.data).includes('req_id')) {
                                    reqidPortMap.set(evt.data.req_id, [\(timestamp), port1]);
                                }
                                evt.data['process_id'] = \(timestamp);
                                window.webkit.messageHandlers.webworkerOnmessage.postMessage(JSON.stringify(evt.data));
                            }
                        } catch(e) {
                            window.webkit.messageHandlers.logging.postMessage('error');
                            window.webkit.messageHandlers.logging.postMessage(e.message);
                        }
                        ''
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
    
    func portPostMessage(res: IpcResponse) {
        print(res.toDic())
        let resStr = ChangeTools.dicValueString(res.toDic())
        self.webview.evaluateJavaScript("""
            window.webkit.messageHandlers.logging.postMessage('req_id: '+\(res.req_id));
            window.webkit.messageHandlers.logging.postMessage('reqidPortMap: '+reqidPortMap.size);
            const [_, port1] = reqidPortMap.get(\(res.req_id));
            port1.postMessage(\(resStr);
            reqidPortMap.delete(\(res.req_id));
            window.webkit.messageHandlers.logging.postMessage('reqidPortMap: '+reqidPortMap.size);
        """) { result, error in
            print(error)
        }
    }
}

extension JsProcessNMM: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "webworkerOnmessage" {
            print("webworkerOnmessage")
            guard let reqBody = message.body as? String else { return }
            let args = JSON.init(parseJSON: reqBody)
            let url = args["url"].stringValue
            let process_id = args["process_id"].intValue
            
//            if self.all_ipc_cache.index(forKey: process_id) == nil { return }
            
            print(url)
            let resBody = DnsNMM.shared.nativeFetch(urlString: url, microModule: self)
            
            var res: IpcResponse
            let req_id = args["req_id"].intValue
            let headers = ["Content-Type":"text/plain"]
//            do {
                if let body = resBody as? String {
                    res = IpcResponse(req_id: req_id, statusCode: 200, body: body, headers: headers)
                } else if let body = resBody as? [String:Any] {
                    res = IpcResponse(req_id: req_id, statusCode: 200, body: ChangeTools.dicValueString(body) ?? "", headers: headers)
                } else if resBody != nil {
//                    try res = IpcResponse(req_id: req_id, statusCode: 200, body: "\(resBody)", headers: headers)
                    res = IpcResponse(req_id: req_id, statusCode: 200, body: "\(resBody!)", headers: headers)
                } else {
                    res = IpcResponse(req_id: req_id, statusCode: 404, body: "no found handler for \(args["pathname"].stringValue)", headers: headers)
                }
//            } catch let err {
//                res = IpcResponse(req_id: req_id, statusCode: 500, body: "\(err)", headers: headers)
//            }
            
            self.portPostMessage(res: res)
        } else if(message.name == "logging") {
            print(message.body)
        } else if(message.name == "portForward") {
            print("portForward")
            guard let data = message.body as? [String:Any], let process_id = data["process_id"] as? Int else { return }
            
            let port1 = "\(process_id)_port1"
            let port2 = "\(process_id)_port2"
            let ipc = JsIpc(port1: port1, port2: port2)
            self.all_ipc_cache[process_id] = ipc
        }
    }
}
                    
                    
