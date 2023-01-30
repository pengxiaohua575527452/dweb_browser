//
//  HotNewsModel.swift
//  Browser
//
//   /26.
//

import Foundation
import SwiftSoup
import UIKit

let sharedCachesMgr = CachesManager()

let CACHEDNEWS_KEY = "cachedNews"

let HISTORIES_KEY = "HistoryCacheList"
let BOOKMARK_KEY = "BookmarkCacheList"
let defaults = UserDefaults.standard
let encoder = JSONEncoder()
let decoder = JSONDecoder()

typealias CachedNesws = Array<Dictionary<String, Any>>

typealias LINKTITLE = String
typealias BookMarkList = Array<Dictionary<String, String>>

class WebModel: NSObject{
    var icon: UIImage?
    var title: String?
    var link: String?
    init(icon: UIImage, title: String, link: String){
        self.icon = icon
        self.title = title
        self.link = link
    }
}
typealias BookMarkModel = WebModel

let hotWebsites = [
    WebModel(icon: UIImage(named: "douyu")!, title: "斗鱼", link: "www.douyu.com"),
    WebModel(icon: UIImage(named: "weibo")!, title: "微博", link: "https://www.weibo.com/"),
    WebModel(icon: UIImage(named: "zhihu")!, title: "知乎", link: "www.zhihu.com"),
    WebModel(icon: UIImage(named: "tengxun")!, title: "腾讯新闻", link: "https://www.qq.com/"),
    WebModel(icon: UIImage(named: "wangyi")!, title: "网易", link: "www.163.com"),
    WebModel(icon: UIImage(named: "douban")!, title: "钱包", link: "http://localhost:8000/index"),
    WebModel(icon: UIImage(named: "bilibili")!, title: "哔哩哔哩", link: "www.bilibili.com"),
    WebModel(icon: UIImage(named: "jingdong")!, title: "京东", link: "www.jd.com")
]

class CachesManager: NSObject{
    let url = URL(string: "https://www.sinovision.net/portal.php?mod=center")!
    @objc dynamic var cachedNewsData = CachedNesws()
    @objc dynamic var bookMarks = BookMarkList()

    func cacheNews(){
        requestNews()

    }
    
    public func fetchNews() -> CachedNesws?{
        guard let cacheDatas = UserDefaults.standard.value(forKey: CACHEDNEWS_KEY) as? CachedNesws else{ return nil }
        return cacheDatas.count > 0 ? cacheDatas : nil
    }
    
    private func requestNews(){
        printDate(string:"start time--" )
        let task = URLSession.shared.dataTask(with: url) { [self] (data, response, error) in
            print("fetch data responsed...")
            if let data = data{
                guard let content = String(data: data, encoding: .utf8) else{ return }
                handleHtml(content: content)
            }
        }
        task.resume()
    }

    private func handleHtml(content:String){
        do {
            let doc: Document = try SwiftSoup.parse(content)
            let hots: Elements? = try doc.getElementsByClass("t9_title item_div").select("a[href]")
            var datas = CachedNesws()
            
            guard hots != nil else { return }
            for (_, nodeEle) in hots!.enumerated().reversed(){
                var dic = Dictionary<String, Any>()
                dic["title"] = try nodeEle.attr("title")
                dic["link"] = try nodeEle.attr("href")
                datas.append(dic)
                if datas.count >= 10{
                    break
                }
            }
            
            if datas.count >= 10{
                UserDefaults.standard.set(datas, forKey: CACHEDNEWS_KEY)
                UserDefaults.standard.synchronize()
                sharedCachesMgr.cachedNewsData = datas
            }
            
        } catch Exception.Error(let type, let message) {
            print(type, message)
        } catch {
            print("error")
        }
        //        print("end time-- \(Date.now)")
        printDate(string:"end time--" )
    }
    
    func printDate(string: String) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日-HH:mm:ss.SSSS"
        print(string + formatter.string(from: date))
    }

}


// MARK: -ReDesigned data handler

// history and bookmark store fammat on local,   dataID is generated by url+time md5
let item2: [[String : String]] = [
    ["dataID":"dsdsasdsdwasdwasdsdwadssq","date":"2022-09-07","iconName":"ksuwjwiq9283jajsdks9823j", "link":"baidu.com", "title":"百度一下"],
    ["dataID":"dsdsasdsdwasdwasdsdwadssq","date":"2022-09-07","iconName":"ksuwjwiq9283jajsdks9823j", "link":"baidu.com", "title":"百度一下"],
    ["dataID":"dsdsasdsdwasdwasdsdwadssq","date":"2022-09-06","iconName":"ksuwjwiq9283jajsdks9823j", "link":"baidu.com", "title":"百度一下"],
    ["dataID":"dsdsasdsdwasdwasdsdwadssq","date":"2022-09-05","iconName":"ksuwjwiq9283jajsdks9823j", "link":"baidu.com", "title":"百度一下"]
]

struct LinkRecord: Codable{
    var link: String        //www.baidu.com
    var imageName: String  //already in local
    var title: String       //
    var dataID: String      //32 digital of md5
    var createdDate: String   //2022年09月12日 星期一
}

struct AppInfo{
    var appName: String
    var appId: String
    var appIconUrl: String?
    var appIcon: UIImage?
}

extension CachesManager{
    func doappendTest(){
        var i = 0
        while i < 9{
            appendLinkItemToCache(type: .history, iconName: "iconame", title: "标题----\(i+1)", linkUrl: "aaa\(i+1).com")
            i += 1
        }
        let list = readList(of: .history)
        print(list)
        let ids = list.map {
            return $0.link
        }
        removeItems(ids: ids, of: .history)
        
        let list2 = readList(of: .history)
        print(list2)

    }
    
    private func appendLinkItemToCache(type :PageType, iconName:String, title:String, linkUrl:String){
        let key = [HISTORIES_KEY,BOOKMARK_KEY][type.rawValue]

        let saveDate = Date(timeInterval:  TimeInterval( 0 * 6 / 3 * 24*3600), since: Date()).detailData()
        
        let record = LinkRecord(link: linkUrl, imageName: iconName, title: title, dataID: linkUrl.md5withDate, createdDate: saveDate)

        var list = readList(of: type)
        var restList = list
        
        if type == .bookmark{
            restList =  list.filter({
                $0.link != linkUrl || type == .history
            })
        }
        restList.append(record)
        list = restList
        
        
        if let encoded = try? encoder.encode(list) {
            defaults.set(encoded, forKey: key)
            defaults.synchronize()
        }
    }
    
    func readList(of type: PageType) -> [LinkRecord]{
        let key = [HISTORIES_KEY,BOOKMARK_KEY][type.rawValue]
        if let savedList = defaults.object(forKey: key) as? Data {
            if let loadedList = try? decoder.decode([LinkRecord].self, from: savedList) {
                return loadedList
            }
        }
        return []
    }
    
    func removeItems(ids:[String], of type: PageType){
        
        let key = [HISTORIES_KEY,BOOKMARK_KEY][type.rawValue]
        let list = readList(of: type)
        let rest = list.filter {
            !ids.contains($0.dataID)
        }
        
        if let encoded = try? encoder.encode(rest) {
            defaults.set(encoded, forKey: key)
            defaults.synchronize()
        }
    }
    
    func readAvailableApps()->[AppInfo]{
        var appNames = sharedInnerAppFileMgr.appIdList
        var infos = [AppInfo]()
        for name in appNames{
            var appInfo = AppInfo(appName: sharedInnerAppFileMgr.currentAppName(appId: name),appId: name)
            let type = sharedInnerAppFileMgr.currentAppType(appId: name)
            if type == .user {
                appInfo.appIconUrl = sharedInnerAppFileMgr.scanImageURL(appId: name)
            } else {
                appInfo.appIcon = sharedInnerAppFileMgr.currentAppImage(appId: name)
            }
            infos.append(appInfo)
        }
        return infos
    }
    
    
    //atDate is the section title of tableView, this method might remove more than one item if there are many same link bookmarks at the same date
    func removeItems(removalUrl: String, atDate: String){
        guard let list = UserDefaults.standard.value(forKey: HISTORIES_KEY) as? [[String : Any]], list.count > 0 else { return }
        
        //history list of the atDate
        let targetList = list.filter({
            $0["date"] as! String == atDate
        })
        
        //history list except today
        var keepList = list.filter({
            $0["date"] as! String != atDate
        })
        
        guard targetList.count > 0 else { return }
        var targetDic = targetList.first
        guard let historyOfDate = targetDic!["list"] as? Array<[String:String]> else { return }
        let newArray = historyOfDate.filter ({
            $0["link"] != removalUrl
        })
        if newArray.count > 0{
            targetDic!["list"] = newArray
            keepList.append(targetDic!)
        }
        
        UserDefaults.standard.set(keepList, forKey: HISTORIES_KEY)
        UserDefaults.standard.synchronize()
        
    }
    
    //atDate is the section title of tableView, this method removes only one item by dataID
    func removeSpecificItem(dataId: String, atDate: String){
        guard let list = UserDefaults.standard.value(forKey: HISTORIES_KEY) as? [[String : Any]], list.count > 0 else { return }
        
        //history list of the atDate
        let targetList = list.filter({
            $0["date"] as! String == atDate
        })
        
        //history list except today
        var keepList = list.filter({
            $0["date"] as! String != atDate
        })
        
        guard targetList.count > 0 else { return }
        var targetDic = targetList.first
        guard let historyOfDate = targetDic!["list"] as? Array<[String:String]> else { return }
        let newArray = historyOfDate.filter ({
            $0["dataID"] != dataId
        })
        if newArray.count > 0{
            targetDic!["list"] = newArray
            keepList.append(targetDic!)
        }
        
        UserDefaults.standard.set(keepList, forKey: HISTORIES_KEY)
        UserDefaults.standard.synchronize()
        
    }
    
}



// MARK: -BookMark
extension CachesManager{
    func fetchBookMarkList() -> [LinkRecord]{
        readList(of: .bookmark)
       
    }
    
    @discardableResult
    open func appendLinkTocache(type: PageType, iconString:String, title:String, linkUrl: String, completion: @escaping(()->())) -> Bool{
        DispatchQueue.global().async { [self] in
            let cachedIconId = self.cacheIcon(iconUrl: iconString, urlFirstChar: String( title.prefix(1)).uppercased())
            appendLinkItemToCache(type: type, iconName: cachedIconId, title: title, linkUrl: linkUrl)
            DispatchQueue.main.async {
                print("-----******in LocalDataMgr appendLinkTocache")

                completion()
            }
        }
        return true
    }
    
    //download or create an image, then save to local file, return local appId of the image
    private func cacheIcon(iconUrl:String, urlFirstChar: String) -> String{
        var hasCachedImage = false
        var cacheImageId: String = "bookmark_def"
        
        if iconUrl.range(of: "http") != nil{
            if let data:Data = try? Data(contentsOf: URL(string: iconUrl)!) {
                if let image:UIImage = UIImage(data: data){
                    cacheImageId = iconUrl.md5
                    ImageHelper.saveImage(image: image, name: cacheImageId)
                    hasCachedImage = true
                }
            }
        }
        if !hasCachedImage{
            if urlFirstChar.count > 0{
                cacheImageId = urlFirstChar.md5
                ImageHelper.saveImage(image: UIImage(letters: urlFirstChar)!, name: cacheImageId)
            }else{
                ImageHelper.saveImage(image: UIImage(named: cacheImageId)!, name: cacheImageId.md5)
            }
        }
        
        
        return cacheImageId
    }
    
}

