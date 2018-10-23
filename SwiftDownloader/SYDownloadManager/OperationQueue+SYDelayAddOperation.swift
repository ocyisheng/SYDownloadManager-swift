//
//  OperationQueue+SYDelayAddOperation.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation
import ObjectiveC.runtime

class __SYOperatinQueueObsever: NSObject {
    var operationQueue:OperationQueue!
    deinit {
        //析构函数
        self.removeObserver(self, forKeyPath: "operationCount")
    }
    init(operationQueue:OperationQueue) {
        self.operationQueue = operationQueue
        super.init()
        self.operationQueue.addObserver(self, forKeyPath: "operationCount", options: NSKeyValueObservingOptions.new, context:nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "operationCount" {
            let counts = change![NSKeyValueChangeKey.newKey] as! Int
            if counts < self.operationQueue.maxConcurrentOperationCount && self.operationQueue.sy_waitingOperations.count >= 1 {
                self.operationQueue.addOperation(self.operationQueue.sy_waitingOperations.first!)
                self.operationQueue.sy_waitingOperations.remove(at: 0)
            }
        }
    }
}

extension OperationQueue {
    var sy_waitingOperations:[Operation] {
        //get
        get {
            var perations = objc_getAssociatedObject(self, "sy_waitingOperations") as? [Operation]
            if perations == nil {
                perations = [Operation]()
                objc_setAssociatedObject(self, "sy_waitingOperations", perations, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return perations!
        }
        set {}
    }
    
    var sy_operatinQueueObsever:__SYOperatinQueueObsever {
        get{
            var observer = objc_getAssociatedObject(self, "sy_operatinQueueObsever") as? __SYOperatinQueueObsever
            if observer == nil {
                observer = __SYOperatinQueueObsever.init(operationQueue: self)
                objc_setAssociatedObject(self, "sy_operatinQueueObsever", observer, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return observer!
        }
        set {}
    }
    
    func syDelayRemove(operation:Operation) {
        if let index = self.sy_waitingOperations.index(of: operation) {
            self.sy_waitingOperations.remove(at: index)
        }
    }
    func syDelayAdd(operation:Operation) {
        if self.operationCount >= self.maxConcurrentOperationCount {
            if self.sy_waitingOperations .contains(operation) == false {
                self.sy_waitingOperations.append(operation)
            }
        }else {
            self.addOperation(operation)
        }
    }

    func syDelayOperations() -> [Operation] {
        var operations  = Array<Operation>()
        operations += self.operations
        operations += self.sy_waitingOperations
        return operations
    }
}
