//
//  InnerAppFileManager.swift
//  BFS
//
//  Created by ui03 on 2022/9/6.
//

import UIKit
import RxSwift

enum InnerAppType: Int {
    case recommend //推荐安装，还没装
    case system //推荐安装，已经安装
    case user   //第三方已安装的
}
let fileMgr = FileManager.default
let sharedAppInfoMgr = AppInfoMgr()


class AppInfoMgr: NSObject {
    
    private let disposeBag = DisposeBag()
    private var appNames: [String:String] = [:]
    private var appImages: [String:UIImage?] = [:]
    private var appLinkDict: [String:String] = [:]
    private var redDict: [String: Bool] = [:]
    
    private var appType: [String : InnerAppType] = [:]
    
    private(set) var appIdList = Set<String>()
    
    var recommendAppMgr = RecommendAppManager()
    var sysAppMgr = SystemAppManager()
    var userAppMgr = UserAppManager()
    
    let redSoptCachePath = documentdir + "/redHot"
    
    override init() {
        super.init()
        loadAppConfigs()
        registerObserver()
    }
    
    private func registerObserver(){
        notifyCenter.addObserver(forName: DownloadAppFinishedNotification, object: nil, queue: .main) { notification in
            guard let userInfo = notification.userInfo as? [String:Any],
                  let appId = userInfo["appId"] as? String,
                  let downloadPath = userInfo["tempZipPath"] as? String else { return }
            self.isInstallAppCompleted(animateAppId: appId, with: downloadPath)
        }
    }
    
    private func loadAppConfigs() {
        totalRedHotContent()
        readAllAppLinkConfig()
    }
    
    func isInstallAppCompleted(animateAppId: String, with zipPath: String){
        let downloadTemPath = documentdir + "/tmp/downloaded/"
        do {
            try FileManager.default.createDirectory(atPath: downloadTemPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error)
        }
        let appId = animateAppId.components(separatedBy: appidCutter).first ?? ""
        let appTempPath = downloadTemPath + appId
        //移除之前残留的zip
        self.removeItem(path: appTempPath)
        NVHTarGzip.sharedInstance().unTarGzipFile(atPath: zipPath, toPath: downloadTemPath) { [self] unzipError in
            if unzipError == nil {
                if self.shouldUpdate(appId: appId) {
                    let appDirectory = documentdir + (self.appType[appId] == .user ? "/user-app/" : "/system-app/")
                    let installPath = appDirectory + appId
                    do {
                        try FileManager.default.createDirectory(atPath: appDirectory, withIntermediateDirectories: true, attributes: nil)
                        if(fileMgr.fileExists(atPath: installPath)){
                            self.removeItem(path: installPath)
                        }
                        try fileMgr.moveItem(atPath: appTempPath, toPath: installPath)
                    }catch {
                        print(error.localizedDescription)
                    }
                    
                    sharedAppInfoMgr.updateRedHot(appId: appId, statue: true)
                    updateLocalSystemAPPData(appId: appId)
                    NotificationCenter.default.post(name:UpdateAppFinishedNotification, object: nil, userInfo: ["appId": appId])

                }else{// 不需要更新
                    NotificationCenter.default.post(name: DownLoadProgressUpdate, object: nil, userInfo: ["progress": "fail", "appId": animateAppId])
                }
                self.removeItem(path: appTempPath)
            }else{
                NotificationCenter.default.post(name: DownLoadProgressUpdate, object: nil, userInfo: ["progress": "fail", "appId": animateAppId])
            }
        }
    }
    
    @discardableResult
    private func removeItem(path: String) -> Bool{
        do{
            try fileMgr.removeItem(atPath: path)
        }catch {
            print(error.localizedDescription)
            return false
        }
        return true
    }
    
    
    private func shouldUpdate(appId: String) -> Bool {
        let desPath = documentdir + "/system-app/\(appId)"
        if FileManager.default.fileExists(atPath: desPath) {
            guard let temFileVersion = appVersion(appId: appId) else { return false} //读取tem 文件夹里面的version
            guard let installedAppVersion = appVersion(appId: appId,isInstalledApp: true) else { return false}
            return appVersionMgr.isVersionIncreasing(nowVersion: installedAppVersion, newVersion: temFileVersion)
        } else {
            return true
        }
    }
    
    func appVersion(appId: String, isInstalledApp: Bool = false) -> String? {
        var midPath = "/tmp/downloaded/"
        if isInstalledApp{
            midPath = appType[appId] == .system ? "/system-app/" : "/user-app/"
        }
        let manifestPath = documentdir + midPath + "\(appId)/boot/bfsa-metadata.json"
        guard let data = fileMgr.contents(atPath: manifestPath) else { return "0"}
        guard let content = String(data: data, encoding: .utf8) else { return "0"}
        let dict = ChangeTools.stringValueDic(content)
        guard let manifest = dict?["manifest"] as? [String:Any] else { return "0"}
        return manifest["version"] as? String
    }
    
    
    private func readAllAppLinkConfig(){
        let sysAppList = sysAppMgr.appDirs()
        let userAppList = userAppMgr.appDirs()
        let recommendAppList = recommendAppMgr.appDirs()
        
        appIdList = Set(Array( recommendAppList + sysAppList + userAppList))
        guard appIdList.count > 0 else { return }
        
        for appId in appIdList {
            if sysAppList.contains(appId) {
                appType[appId] = .system
                appNames[appId] = sysAppMgr.appName(appId: appId)
                appImages[appId] = sysAppMgr.appIcon(appId: appId)
                
            } else if userAppList.contains(appId) {
                appType[appId] = .user
                appNames[appId] = userAppMgr.appName(appId: appId)
            } else if recommendAppList.contains(appId) {
                appType[appId] = .recommend
                appNames[appId] = recommendAppMgr.appName(appId: appId)
                appImages[appId] = recommendAppMgr.appIcon(appId: appId)
            }
        }
    }
    
    func typeOfApp(appId:String) -> InnerAppType{
        return appType[appId] ?? .recommend
    }
    //写入轮询更新数据
    func writeUpdateContent(appId: String, json: [String:Any]?) {
        guard json != nil else { return }
        let type = currentAppType(appId: appId)
        if type == .system {
            sysAppMgr.writeUpdateInfoToTmpFile(appId: appId, json: json!)
        } else if type == .recommend {
            recommendAppMgr.writeUpdateInfoToTmpFile(appId: appId, json: json!)
        } else if type == .user {
            userAppMgr.writeUpdateInfoToTmpFile(appId: appId, json: json!)
        }
    }
    
    
    //更新文件状态为扫码
    func updateUserType(appId: String) {
        appType[appId] = .user
        appNames[appId] = userAppMgr.appName(appId: appId)
    }
    //获取扫码的图片地址
    func scanImageURL(appId: String) -> String {
        return userAppMgr.appIconUrlString(appId: appId) ?? ""
    }
    //获取扫码后app的下载地址
    func scanDownloadURLString(appId: String) -> String {
        return appDownloadUrl(appId: appId) ?? ""
    }
    //扫码下载app
    func scanToDownloadApp(appId: String, dict: [String:Any]) {
        self.addAPPFromScan(appId: appId, dict: dict)
        self.updateUserType(appId: appId)
        RefreshManager.saveLastUpdateTime(appId: appId, time: Date().timeStamp)
        self.writeUpdateContent(appId: appId, json: dict)
    }
    
    //获取system-app最新的版本信息
    func fetchSystemAppNewVersion(appId: String, urlString: String) {
        
        //system-app升级操作
        //1、点击升级，退回到桌面界面
        //2、开始动画，下载文件
        operateMonitor.startAnimationMonitor.onNext(appId)
        sharedNetworkMgr.downloadApp(appId: appId, urlString: urlString)
        
    }
    
    //system-app升级后，更新本地文件，提供给app使用
    func updateSystemAppFile(appId: String, path: String) {
        let desPath = documentdir + "/system-app"
        
        NVHTarGzip.sharedInstance().unTarGzipFile(atPath: path, toPath: desPath) { error in
            if error == nil {
                let schemePath = desPath + "/\(appId)/sys"   //后面看返回数据修改
                Schemehandler.setupHTMLCache(appId: appId, fromPath: schemePath)
                RefreshManager.saveLastUpdateTime(appId: appId, time: Date().timeStamp)
            }
        }
    }
    
    //扫码添加安装的app数据
    func addAPPFromScan(appId: String, dict: [String:Any]) {
        userAppMgr.writeLinkJson(appId: appId, dict: dict)
    }
    
    //获取system-app的entryPath
    func systemAPPEntryPath(appId: String) -> String? {
        return sysAppMgr.fetchEntryPath(appId: appId)
    }
    
    //获取system-app的appType
    func systemAPPType(appId: String) -> String? {
        return sysAppMgr.readAppType(appId: appId)
    }
    
    //获取system-app的web地址
    func systemWebAPPURLString(appId: String) -> String? {
        return sysAppMgr.readWebAppURLString(appId: appId)
    }
    //获取system-app的版本号
    func systemAPPVersion(appId: String) -> String {
        return sysAppMgr.readMetadataVersion(appId: appId) ?? ""
    }
    
    //从bfs-app-id/tmp/autoUpdate/缓存中读取url数据
    func appDownloadUrl(appId: String) -> String? {
        let cacheInfo = readCacheUpdateInfo(appId: appId)
        let caches = cacheInfo?["files"] as? [[String:Any]]
        let fileInfo = caches?.first
        guard let urlstring = fileInfo?["url"] as? String else { return nil }
        return urlstring
    }
    
    //读取缓存更新的信息
    private func readCacheUpdateInfo(appId: String) -> [String:Any]? {
        
        let type = currentAppType(appId: appId)
        if type == .system {
            return sysAppMgr.readCacheUpdateInfo(appId: appId)
        } else if type == .recommend {
            return recommendAppMgr.readCacheUpdateInfo(appId: appId)
        } else if type == .user {
            return userAppMgr.readCacheUpdateInfo(appId: appId)
        }
        return nil
    }
    
    
    //取消缓存的下载信息，重新下载最新信息
    private func reloadUpdateFile(appId: String, cancelUrlString: String?, urlString: String?) {
        sharedNetworkMgr.cancelNetworkRequest(urlString: cancelUrlString)
        if urlString != nil {
            operateMonitor.startAnimationMonitor.onNext(appId)
            sharedNetworkMgr.downloadApp(appId: appId, urlString: urlString!)
        }
    }
    
    //判断是否有新的更新消息
    private func hasNewUpdateInfo(appId: String) -> Bool {
        let type = currentAppType(appId: appId)
        if type == .system {
            return sysAppMgr.isNewUpdateInfo(appId: appId)
        } else if type == .recommend {
            return recommendAppMgr.isNewUpdateInfo(appId: appId)
        } else if type == .user {
            return userAppMgr.isNewUpdateInfo(appId: appId)
        }
        return false
    }
}

//MARK: 获取app信息
extension AppInfoMgr {
    
    //根据文件名获取app名称
    func currentAppName(appId: String) -> String {
        return appNames[appId] ?? ""
    }
    //根据文件名获取app图片
    func currentAppImage(appId: String) -> UIImage? {
        return appImages[appId] ?? nil
    }
    //根据文件名获取app类型
    func currentAppType(appId: String) -> InnerAppType? {
        return appType[appId]
    }
    
}

//MARK: 更新app下载后的信息
extension AppInfoMgr {
    //获取app红点信息
    private func totalRedHotContent() {
        let path = redSoptCachePath
        guard let content = try? FileSystemManager.readFile(at: URL(fileURLWithPath: path), with: true) else { return }
        redDict = ChangeTools.stringValueDic(content) as? [String:Bool] ?? [:]
    }
    
    //更新新版本红点
    func updateRedHot(appId: String, statue: Bool) {
        redDict[appId] = statue
        
        guard let redString = ChangeTools.dicValueString(redDict) else { return }
        try? FileSystemManager.writeFile(at: URL(fileURLWithPath: redSoptCachePath), with: redString, recursive: true, encoding: true)
    }
    //得到红点状态
    func redHot(appId: String) -> Bool {
        return redDict[appId] ?? false
    }
    
    //更新本地文件数据
    func updateLocalSystemAPPData(appId: String) {
        if !appIdList.contains(appId) {
            appIdList.insert(appId)
        }
        appType[appId] = .system
        appNames[appId] = sysAppMgr.appName(appId: appId)
        appImages[appId] = sysAppMgr.appIcon(appId: appId)
    }
}
