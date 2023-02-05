//
//  Promise.swift
//  BFExplorer
//
//  Created by biyou on 2023/2/4.
//

import Foundation

class Promise<T> {
    typealias ResolveCallback = (T) -> Void
    typealias RejectCallback = (Error) -> Void
    typealias AsyncTask = (@escaping ResolveCallback,@escaping RejectCallback) -> Void
    
    let task: AsyncTask
    
    var resolveCallback: ResolveCallback?
    var rejectCallback: RejectCallback?
    
    init(_ task: @escaping AsyncTask) {
        self.task = task
    }
    
    private func resolve(result: T) {
        self.resolveCallback?(result)
    }
    
    private func reject(error: Error) {
        self.rejectCallback?(error)
    }
    
    func startTask(success: @escaping ResolveCallback,failed:@escaping RejectCallback) {
        self.resolveCallback = success
        self.rejectCallback = failed
        self.task({ self.resolve(result: $0) }, { self.reject(error: $0) })
    }
    
    func then<U>(f:@escaping (T) -> Promise<U>) -> Promise<U> {
        return Promise<U> { (resolve, reject) in
            self.task(
                { (result) in
                    // result = ”“ 和String函数处理过的值
                    let wrapped = f(result)
                    // wrapped是promise对象，通过调用startTask来执行内部异步任务，然后回调了then内部Promise的reslove，而这个resolve和failed又会由下一个then来确定
                    wrapped.startTask(success: {resolve($0)}, failed: {reject($0)})
                },
                { (error) in
                    reject(error)
            })
        }
    }
}
