//
//  SYDownloadTaskStore.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation
import UIKit

class SYDownloadTaskStore: NSObject {
    private var outputStreamDic = Dictionary<String, OutputStream>()//储存属性
    private var taskModelDic = Dictionary<String, SYDownloadTaskModel>()//
    private var cacheDirect: String! {
        //只读计算属性
        var direct:URL! = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
         direct.appendPathComponent("downloadOperationQueueCache")
        let dir = direct.relativePath
        if FileManager.default.fileExists(atPath: dir) == false {
            //必比不出错
            try! FileManager.default.createDirectory(atPath:dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }
    override init() {
        super.init()
        //声明 不可变可为nil的字典 ，后边解归档的数据是any，需要强转Dictionary<String, SYDownloadTaskModel>
        //初始化 taskModelDic
        print("cacheDirect:" + self.cacheDirect)
        let dic = NSKeyedUnarchiver.unarchiveObject(withFile: self.cacheDirect + "/" + "downloadTask_archives.arch") as? Dictionary<String, SYDownloadTaskModel>
        if dic != nil {
            for (_, model) in dic! {
                if model.state == .downloading || (model.state == .waiting && model.currenSize > 0) {
                    model.state = .suspend
                }else if model.state == .waiting {
                    model.state = .added
                }
            }
            self.taskModelDic = dic!
        }
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate), name: Notification.Name.UIApplicationWillTerminate, object: nil)
        
    }
   
    func addTaskModle(with URLStr: String, type: String!) {
        if self.taskModelDic[URLStr] == nil {
            let model = SYDownloadTaskModel()
            model.url = URLStr
            model.type = type
            model.cacheFileName = self.md5(str: URLStr) + "." + type
            self.taskModelDic[URLStr] = model
        }
    }
    
    func deleteTaskModle(with URLStr: String) {
        let cacheFile = self.cacheFilePath(with: URLStr)
        self.taskModelDic.removeValue(forKey: URLStr)
        DispatchQueue.global().async {
            try? FileManager.default.removeItem(atPath: cacheFile)
        }
        
    }
    func openOutputStream(with response: URLResponse, for URLStr: String) {
        if let model = self.taskModelDic[URLStr] {
            if model.currenSize == 0 {
                model.totalSize = response.expectedContentLength
            }
        }
        let url = URL.init(fileURLWithPath: self.cacheFilePath(with: URLStr))
        let stream = OutputStream.init(url: url, append: true)
        stream?.open()
        self.outputStreamDic[URLStr] = stream
        
    }
    func appendOutputStream(with data: Data, for URLStr: String) {
        
        if let stream = self.outputStreamDic[URLStr] {
            let bytes = [UInt8](data)
            stream.write(UnsafePointer<UInt8>(bytes), maxLength: bytes.count)
            if let model = self.taskModelDic[URLStr] {
                model.currenSize += Int64(bytes.count)
                if let total = model.totalSize {
                    if  let current = model.currenSize {
                        model.progress = Float(Float(current) / Float(total)) 
                    }
                }
            }
        }
       
    }
    func closeOutputStream(for URLStr: String) {
        if let stream = self.outputStreamDic[URLStr] {
            stream.close()
            self.outputStreamDic.removeValue(forKey: URLStr)
        }
    }
    func taskModel(with URLStr: String) -> SYDownloadTaskModel? {
        return  self.taskModelDic[URLStr]
    }
    func taskModels() -> Dictionary<String, SYDownloadTaskModel>{
        return  self.taskModelDic
    }
    func cacheFilePath(with URLStr: String) -> String {
        return self.cacheDirect + "/" + (self.taskModelDic[URLStr]?.cacheFileName!)!
    }
    
    private func md5(str: String) -> String {
        let cStr = str.cString(using: .utf8)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5(cStr!,(CC_LONG)(strlen(cStr!)), buffer)
        let md5String = NSMutableString.init()
        for i in 0 ..< CC_MD5_DIGEST_LENGTH {
            md5String.appendFormat("%02x", buffer[Int(i)])
        }
        free(buffer)
        return md5String as String
    }
    
    @objc private func willTerminate() {
    print(self.taskModelDic)
        NSKeyedArchiver.archiveRootObject(self.taskModelDic, toFile: self.cacheDirect + "/" + "downloadTask_archives.arch")
    }
}
