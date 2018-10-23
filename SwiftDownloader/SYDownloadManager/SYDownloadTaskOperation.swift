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
    private  var dataTask: URLSessionDataTask?
    private var _isExecuting: Bool {
        willSet { willChangeValue(forKey: "isExecuting") }
        didSet { didChangeValue(forKey: "isExecuting") }
    }
    private var _isFinished: Bool {
        willSet { willChangeValue(forKey: "isFinished") }
        didSet { didChangeValue(forKey: "isFinished") }
    }
    private var _isCancelled: Bool {
        willSet { willChangeValue(forKey: "isCancelled") }
        didSet { didChangeValue(forKey: "isCancelled") }
    }
   
    init(dataTask: URLSessionDataTask) {
        self.dataTask = dataTask
        self.identify = dataTask.currentRequest?.url?.absoluteString
        _isFinished = false
        _isExecuting = false
        _isCancelled = false
        super.init()
    }
    override var isExecuting: Bool {
        return _isExecuting
    }
    override var isFinished: Bool {
        return _isFinished
    }
    override var isCancelled: Bool {
        return _isCancelled
    }
    override var isAsynchronous: Bool {
        return true
    }
    func suspendTask() {
        if self.isExecuting {
            _isExecuting = false
        }
        self.cancel()
    }
    func removeTask() {
        self.suspendTask()
    }
    func completionTask() {
        if self.isFinished == false {
            _isExecuting = false
            _isFinished = true
        }
    }
    override func start() {
        if self.isCancelled {
            _isFinished = true
        }else {
            _isExecuting = true
            self.dataTask?.resume()
        }
    }
    override func cancel() {
        _isCancelled = true
        self.dataTask?.cancel()
        self.dataTask = nil
        //设置finished 为YES，operation将自动从queue中移除
        self.completionTask()
    }
    
}
