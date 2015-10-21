//
//  Materialize.swift
//  Rx
//
//  Created by Junior B. on 21/10/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

class MaterializeSink<Element, O : ObserverType where O.E == Event<Element>>: Sink<O>, ObserverType {
    
    override init(observer: O, cancel: Disposable){
        super.init(observer: observer, cancel: cancel)
    }

    func on(event: Event<Element>) {
        switch event {
        case .Next(let value):
            observer?.on(.Next(Event.Next(value)))
        case .Error(let e):
            observer?.on(.Next(Event.Error(e)))
            observer?.on(.Completed)
            self.dispose()
        case .Completed:
            observer?.on(.Next(Event.Completed))
            observer?.on(.Completed)
            self.dispose()
        }
    }
}

class Materialize<Element> : Producer<Event<Element>> {
    
    let source: Observable<Element>
    
    init(source: Observable<Element>) {
        self.source = source
    }
    
    override func run<O: ObserverType where O.E == Event<Element>>(observer: O, cancel: Disposable, setSink: (Disposable) -> Void) -> Disposable {
        let sink = MaterializeSink(observer: observer, cancel: cancel)
        setSink(sink)
        return source.subscribeSafe(sink)
    }
}