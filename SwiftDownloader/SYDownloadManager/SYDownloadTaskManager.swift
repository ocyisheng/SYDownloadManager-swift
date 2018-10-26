//
//  SYDownloadTaskManager.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation

class SYDownloadTaskManager: NSObject,URLSessionDataDelegate {
    private var sessionConfig = URLSessionConfiguration.default
    private var taskStore = SYDownloadTaskStore.init()
    private var downloadOperationQueue = OperationQueue.init()
    private var session: URLSession?
    private var allowsCellularAccess = false
    private var maxTaskCount = 3
    
    var downloadTaskCompletionHandle: ((_ url: String, _ locationPath: String) -> Void)?
    var downloadTaskProgressHandle: ((_ url: String, _ progress: Float) -> Void)?
    var downloadTaskStateChangedHandle:((_ model: SYDownloadTaskModel) -> Void)?
    var downloadManagerAllowCellularAccessHandle:(() ->Bool)?
    
    override init() {
        super.init()
        self.downloadOperationQueue.maxConcurrentOperationCount = 3
        self.sessionConfig.allowsCellularAccess = false
        self.session = URLSession.init(configuration: self.sessionConfig, delegate: self, delegateQueue: OperationQueue.init())
    }
    func locationPath(url: String) -> String {
        return self.taskStore.cacheFilePath(with:url)
    }
    func tasModel(url: String) -> SYDownloadTaskModel {
        return self.taskStore.taskModel(with: url)!
    }

    func allDownloadTaskModles() -> [SYDownloadTaskModel] {
        return [SYDownloadTaskModel]((self.taskStore.taskModels()?.values)!)
    }
    //设置移动网络是否导通
    func setCellularAccess(isAllow: Bool) {
        self.allowsCellularAccess = isAllow
        if self.allowsCellularAccess == false {
            self.downloadOperationQueue.cancelAllOperations()
            for obj in self.downloadOperationQueue.syDelayOperations() {
                let operation = obj as! SYDownloadTaskOperation
                self.downloadOperationQueue.syDelayRemove(operation: operation)
                operation.suspendTask()
                self.setTaskState(state: .suspend, for: operation.identify)
            }
        }
        self.sessionConfig.allowsCellularAccess = isAllow
    }
    func setMaxTask(count:Int) -> Void {
        self.maxTaskCount = count
        self.downloadOperationQueue.maxConcurrentOperationCount = count
    }
    func addTask(url: String, type: String) -> Void {
        self.taskStore.addTaskModle(with: url, type: type)
        self.setTaskState(state: .added, for: url)
    }
    func deleteTask(url: String) -> Void {
        if let model = self.taskStore.taskModel(with: url) {
            if model.state == SYDownloadTaskState.downloading || model.state == SYDownloadTaskState.waiting {
                if let operation =  self.taskOpertation(url: url) {
                    operation.removeTask()
                    self.downloadOperationQueue.syDelayRemove(operation: operation)
                }
            }
            self.taskStore.deleteTaskModle(with: url)
        }
    }
    
    func suspendTask(url: String) -> Void {
        if let model = self.taskStore.taskModel(with: url) {
            if model.state == SYDownloadTaskState.downloading || model.state == SYDownloadTaskState.waiting  {
                if let operation = self.taskOpertation(url: url) {
                    operation.suspendTask()
                    self.downloadOperationQueue.syDelayRemove(operation: operation)
                }
                self.setTaskState(state: .suspend, for: url)
            }
        }
    }
    
    func resumeTask(url:String) -> Void {
        if let model = self.taskStore.taskModel(with: url) {
             if model.state == SYDownloadTaskState.added || model.state == SYDownloadTaskState.suspend || model.state == SYDownloadTaskState.fail {
                var request = URLRequest.init(url:(URL.init(string: url))!)
                let currenSizeStr = NSString.init(format: "%lld", model.currenSize!)
                request.setValue("bytes=\(currenSizeStr)-", forHTTPHeaderField: "range")
                let dataTask = self.session?.dataTask(with: request)
                let taskOp = SYDownloadTaskOperation.init(dataTask: dataTask!)
                self.downloadOperationQueue.syDelayAdd(operation: taskOp)
                self.setTaskState(state: .waiting, for: url)
            }
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print("error:\(String(describing: error))")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let url = task.originalRequest?.url?.absoluteString

        self.taskOpertation(url:url!)?.completionTask()
        self.taskStore.closeOutputStream(for: url!)
        
        if error == nil {
            //完成
            if let handle = self.downloadTaskCompletionHandle {
                handle(url!, self.taskStore.cacheFilePath(with: url!))
            }
            self.setTaskState(state: .finshed, for: url!)
        }else {
            let nserror = error! as NSError
            if (nserror.code != -999) {
                if (nserror.code == -1009 && self.allowsCellularAccess == false) {
                    if let handle = self.downloadManagerAllowCellularAccessHandle {
                        let isAllow = handle()
                        self.setCellularAccess(isAllow: isAllow)
                    }
                }
            }else {
                //主动取消
            }
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        //收到数据
        let url = dataTask.originalRequest?.url?.absoluteString
        self.taskStore.openOutputStream(with: response, for: url!)
        self.setTaskState(state: .downloading, for: url!)
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        //数据进度
        let url = dataTask.originalRequest?.url?.absoluteString
        self.taskStore.appendOutputStream(with: data, for: url!)
        if let handle = self.downloadTaskProgressHandle {
            if let model = self.taskStore.taskModel(with: url!) {
                //回调进度
                handle(url!,model.progress!)
            }
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        //重定向
        completionHandler(request)
    }
    
    //获取operation
    private func taskOpertation(url:String) -> SYDownloadTaskOperation? {
        let operations = self.downloadOperationQueue.syDelayOperations()
        var taskOperation:SYDownloadTaskOperation? = nil
        for obj in operations {
            let op = obj as! SYDownloadTaskOperation
            if op.identify == url {
                taskOperation = op
                break
            }
        }
        return taskOperation
    }
    
    //设置task的状态
    private func setTaskState(state: SYDownloadTaskState, for URL: String) {
        self.taskStore.taskModel(with: URL)?.state = state
        if let handle = self.downloadTaskStateChangedHandle {
            handle(self.taskStore.taskModel(with: URL)!)
        }
    }
   
}

