//
//  SYDownloadTaskStore.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation
import Darwin
class SYDownloadTaskStore: NSObject {
    
    
    func addTaskModle(withURLStr: String, type: String) {
        
        }
    
    func deleteTaskModle(withURLStr: String) {
        
        }
    func openOutputStream(withResponse: URLResponse, forURLStr: String) {
        
        }
    func appendOutputStream(withData: Data, forURLStr: String) {
    
        }
    func closeOutputStream(forURLStr: String) {
        
        }
    func taskModel(withURLStr: String) -> SYDownloadTaskModel? {
        return  nil
    }
    func taskModels() -> NSDictionary?{
        return  nil
    }
    func cacheFilePath(withURLStr: String) -> String? {
        return nil
    }
}
