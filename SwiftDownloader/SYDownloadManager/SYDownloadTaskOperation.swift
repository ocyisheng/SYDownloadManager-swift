//
//  SYDownloadTaskOperation.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation.NSOperation

class SYDownloadTaskOperation: Operation {
    var identify: String!
    private var dataTask: URLSessionDataTask?
    private var _executing: Bool {
        willSet { willChangeValue(forKey: "isExecuting") }
        didSet { didChangeValue(forKey: "isExecuting") }
    }
    private var _finished: Bool {
        willSet { willChangeValue(forKey: "isFinished") }
        didSet { didChangeValue(forKey: "isFinished") }
    }
    private var _cancelled: Bool {
        willSet { willChangeValue(forKey: "isCancelled") }
        didSet { didChangeValue(forKey: "isCancelled") }
    }
   
    init(dataTask: URLSessionDataTask) {
       
        self.dataTask = dataTask
        self.identify = dataTask.currentRequest?.url?.absoluteString
        _finished = false
        _executing = false
        _cancelled = false
        super.init()
    }
    override var isExecuting: Bool {
        return _executing
    }
    override var isFinished: Bool {
        return _finished
    }
    override var isCancelled: Bool {
        return _cancelled
    }
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        if self.isCancelled {
            _finished = true
        }else {
            _executing = true
            self.dataTask?.resume()
        }
    }
    override func cancel() {
        _cancelled = true
        self.dataTask?.cancel()
        self.dataTask = nil
        //设置finished 为YES，operation将自动从queue中移除
        self.completionTask()
    }
    
    func suspendTask() {
        if self.isExecuting {
            _executing = false
        }
        self.cancel()
    }
    
    func removeTask() {
        self.suspendTask()
    }
    
    func completionTask() {
        if self.isFinished == false {
            _executing = false
            _finished = true
        }
    }
  
    
}
