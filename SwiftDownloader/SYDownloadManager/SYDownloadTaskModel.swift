//
//  SYDownloadTaskModel.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation

enum SYDownloadTaskState:Int {
    case added = 1, waiting, downloading, suspend, finshed, fail
}

class SYDownloadTaskModel: NSObject,NSCoding {
    var url: String?
    var type: String?
    var cacheFileName: String?
    var totalSize: Int64! = 0
    var currenSize: Int64! = 0
    var progress: Float! = 0.0
    private var _state:Int?
    var state: SYDownloadTaskState? {
        set {
            _state = newValue?.rawValue
        }
        get {
            return SYDownloadTaskState.init(rawValue: _state!)
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.url, forKey: "url")
        aCoder.encode(self.type, forKey: "type")
        aCoder.encode(self.cacheFileName, forKey: "cacheFileName")
        aCoder.encode(self.totalSize, forKey: "totalSize")
        aCoder.encode(self.currenSize, forKey: "currenSize")
        aCoder.encode(self.progress, forKey: "progress")
        aCoder.encode(self._state, forKey: "_state")
    }
    required convenience init(coder aDecoder: NSCoder) {
        self.init()
        url = aDecoder.decodeObject(forKey: "url") as? String
        type = aDecoder.decodeObject(forKey: "type") as? String
        cacheFileName = aDecoder.decodeObject(forKey: "cacheFileName") as? String
        progress =  aDecoder.decodeObject(forKey: "progress") as? Float
        totalSize =  aDecoder.decodeObject(forKey: "totalSize") as? Int64
        currenSize =  aDecoder.decodeObject(forKey: "currenSize") as? Int64
        _state =  aDecoder.decodeObject(forKey: "_state") as? Int
    }
}
