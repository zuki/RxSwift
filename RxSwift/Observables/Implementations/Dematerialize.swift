//
//  Dematerialize.swift
//  Rx
//
//  Created by Junior B. on 21/10/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

class DematerializeSink<Element, O : ObserverType where O.E == Element>: Sink<O>, ObserverType {
    
    override init(observer: O, cancel: Disposable){
        super.init(observer: observer, cancel: cancel)
    }
    
    func on(event: Event<Event<Element>>) {
        switch event {
        case .Next(let val):
            switch val {
            case .Next(let value):
                observer?.on(.Next(value))
            case .Error(let e):
                observer?.on(.Error(e))
                observer?.on(.Completed)
                self.dispose()
            case .Completed:
                observer?.on(.Completed)
                self.dispose()
            }
        case .Error(let e):
            observer?.on(.Error(e))
            observer?.on(.Completed)
            self.dispose()
        case .Completed:
            observer?.on(.Completed)
            self.dispose()
        }
    }
}

class Dematerialize<Element> : Producer<Element> {
    
    let source: Observable<Event<Element>>
    
    init(source: Observable<Event<Element>>) {
        self.source = source
    }
    
    override func run<O: ObserverType where O.E == Element>(observer: O, cancel: Disposable, setSink: (Disposable) -> Void) -> Disposable {
        let sink = DematerializeSink(observer: observer, cancel: cancel)
        setSink(sink)
        return source.subscribeSafe(sink)
    }
}