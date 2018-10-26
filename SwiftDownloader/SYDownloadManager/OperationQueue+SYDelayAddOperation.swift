//
//  OperationQueue+SYDelayAddOperation.swift
//  SwiftDownloader
//
//  Created by gao on 2018/10/22.
//  Copyright © 2018年 gao. All rights reserved.
//

import Foundation
import ObjectiveC.runtime

private var sy_waitingOperations_key: Void?
private var sy_operatinQueueObsever_key: Void?

extension OperationQueue {
    var sy_waitingOperations:[Operation] {
        get {
            var perations = objc_getAssociatedObject(self, &sy_waitingOperations_key) as? [Operation]
            if perations == nil {
                perations = [Operation]()
                objc_setAssociatedObject(self, &sy_waitingOperations_key, perations, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return perations!
        }
        set {
            objc_setAssociatedObject(self,  &sy_waitingOperations_key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var sy_operatinQueueObsever:__SYOperatinQueueObsever? {
        get {
            return objc_getAssociatedObject(self, &sy_operatinQueueObsever_key) as? __SYOperatinQueueObsever
        }
        set {
            objc_setAssociatedObject(self, &sy_operatinQueueObsever_key, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func syDelayRemove(operation:Operation) {
        if let index = self.sy_waitingOperations.index(of: operation) {
            self.sy_waitingOperations.remove(at: index)
        }
    }
    func syDelayAdd(operation:Operation) {
        self.initlizeObsever()
        if self.operationCount >= self.maxConcurrentOperationCount {
            if self.sy_waitingOperations .contains(operation) == false {
                self.sy_waitingOperations.append(operation)
            }
        }else {
            self.addOperation(operation)
        }
    }
    
    func syDelayOperations() -> [Operation] {
        self.initlizeObsever()
        var operations  = Array<Operation>()
        operations += self.operations
        operations += self.sy_waitingOperations
        return operations
    }
    
   private func initlizeObsever() -> Void {
        if self.sy_operatinQueueObsever == nil {
            self.sy_operatinQueueObsever =  __SYOperatinQueueObsever.init(operationQueue: self)
        }
    }
}

class __SYOperatinQueueObsever: NSObject {
    var operationQueue:OperationQueue!
    deinit {
        //析构函数
        self.removeObserver(self, forKeyPath: "operationCount")
    }
    init(operationQueue:OperationQueue) {
        super.init()
        self.operationQueue = operationQueue
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
