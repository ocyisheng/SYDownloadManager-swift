//
//  SYDownloadTaskModel.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation

enum SYDownloadTaskState:Int {
    case added = 1, downloading, susped, finshed, waiting, fail
}

class SYDownloadTaskModel: NSObject,NSCoding {
    var url: String?
    var type: String?
    var cacheFileName: String?
    var totalSize: Int64?
    var currenSize: Int64?
    var progress: Float?
    var state: SYDownloadTaskState?
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.url)
        aCoder.encode(self.type)
        aCoder.encode(self.cacheFileName)
        aCoder.encode(self.totalSize)
        aCoder.encode(self.currenSize)
        aCoder.encode(self.progress)
        aCoder.encode(self.state)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        self.init()
        aDecoder.decodeObject(forKey: "url")
        aDecoder.decodeObject(forKey: "type")
        aDecoder.decodeObject(forKey: "cacheFileName")
        aDecoder.decodeFloat(forKey: "progress")
        aDecoder.decodeInt64(forKey: "totalSize")
        aDecoder.decodeInt64(forKey: "currenSize")
        aDecoder.decodeInteger(forKey: "state")
    }
}
