//
//  AppDelegate.swift
//  Browser
//
//         
//

import UIKit


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.makeKeyAndVisible()
//
//        sharedCachesMgr.cacheNews()
//        appVersionMgr.startCheck()
//
//        window?.rootViewController = UINavigationController(rootViewController: FirstViewController())
        DispatchQueue.global().async {
            let app = HttpServer()

            app.get("/test") { req, res, next in
                print("listen get 26000")
                print(req.header)
                res.json(["a":"1"])
            }
            app.post("/test") { req, res, next in
                print("listen post 26000")
                print(req.header)
                print(req.body)
                res.json(["b":1])
            }

            app.listen(26000)
        }
        
//        Task(priority: .background) {
//            let app = HttpServer()
//
//            app.get("/test") { req, res, next in
//                print("listen listen 26000")
//                print(req.header)
//                res.json(["a":"1"])
//            }
//
//            app.listen(26000)
//        }
        
        DnsNMM.shared.bootstrap()
       
        return true
    }
    
}

extension UIApplication {
var statusBarUIView: UIView? {

    if #available(iOS 13.0, *) {
        let tag = 3848245

        let keyWindow = UIApplication.shared.connectedScenes
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows.first

        if let statusBar = keyWindow?.viewWithTag(tag) {
            return statusBar
        } else {
            let height = keyWindow?.windowScene?.statusBarManager?.statusBarFrame ?? .zero
            let statusBarView = UIView(frame: height)
            statusBarView.tag = tag
            statusBarView.layer.zPosition = 999999
            statusBarView.backgroundColor = .red
            keyWindow?.addSubview(statusBarView)
            return statusBarView
        }

    } else {

        if responds(to: Selector(("statusBar"))) {
            return value(forKey: "statusBar") as? UIView
        }
    }
    return nil
  }
}


