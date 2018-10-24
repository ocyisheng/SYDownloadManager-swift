//
//  SYDownloadTaskStore.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation

class SYDownloadTaskStore: NSObject {
    private var outputStreamDic = Dictionary<String, OutputStream>()//储存属性
    private var taskModelDic: Dictionary<String, SYDownloadTaskModel>!
    private var cacheDirect: String! {
        //只读计算属性
        var direct:String! = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.absoluteString
         direct += "/downloadOperationQueueCache"
        if FileManager.default.fileExists(atPath: direct) == false {
            //这个有error需要try
           try? FileManager.default.createDirectory(atPath: direct, withIntermediateDirectories: true, attributes: nil)
        }
        return direct
    }
  
    override init() {
        super.init()
        //声明 不可变可为nil的字典 ，后边解归档的数据是any，需要强转Dictionary<String, SYDownloadTaskModel>
        //初始化 taskModelDic
        let dic = NSKeyedUnarchiver.unarchiveObject(withFile: self.cacheDirect + "/downloadTask_archives.arch") as? Dictionary<String, SYDownloadTaskModel>
        for (_, model) in dic ?? Dictionary<String, SYDownloadTaskModel>() {
            if model.state == SYDownloadTaskState.downloading || model.state == SYDownloadTaskState.waiting {
                model.state = SYDownloadTaskState.susped
            }
        }
        self.taskModelDic = dic
    }
    func addTaskModle(with URLStr: String, type: String!) {
        if self.taskModelDic[URLStr] == nil {
            let model: SYDownloadTaskModel = SYDownloadTaskModel()
            model.url = URLStr
            model.type = type
            model.cacheFileName = URLStr + "." + type
            self.taskModelDic[URLStr] = model
        }
    }
    
    func deleteTaskModle(with URLStr: String) {
        let cacheFile = self.cacheFilePath(with: URLStr)
        self.taskModelDic.removeValue(forKey: cacheFile)
        DispatchQueue.global().async {
            try? FileManager.default.removeItem(atPath: URLStr)
        }
        
    }
    func openOutputStream(with response: URLResponse, for URLStr: String) {
        let model = self.taskModelDic[URLStr]
        if model?.currenSize == 0 {
            model?.totalSize = response.expectedContentLength
        }
        let stream = OutputStream.init(url: URL.init(fileURLWithPath: URLStr), append: true)
        stream?.open()
        self.outputStreamDic[URLStr] = stream
        
    }
    func appendOutputStream(with data: Data, for URLStr: String) {
        
        if let stream = self.outputStreamDic[URLStr] {
            let bytes = [UInt8](data)
            stream.write(UnsafePointer<UInt8>(bytes), maxLength: bytes.count)
            let model = self.taskModelDic[URLStr]
            model?.currenSize! += Int64(bytes.count)
            if let total = model?.totalSize {
                if  let current = model?.currenSize {
                    model?.progress = Float(current) / Float(total)
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
    func taskModels() -> Dictionary<String, SYDownloadTaskModel>?{
        return  self.taskModelDic
    }
    func cacheFilePath(with URLStr: String) -> String {
        return self.cacheDirect + "/" + (self.taskModelDic[URLStr]?.cacheFileName!)!
    }
}
