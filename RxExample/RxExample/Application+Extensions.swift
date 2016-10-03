//
//  UIApplication+Extensions.swift
//  RxExample
//
//  Created by Krunoslav Zaher on 8/20/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)
    import UIKit
    private typealias OSApplication = UIApplication
#elseif os(OSX)
    import Cocoa
    private typealias OSApplication = NSApplication
#endif

extension OSApplication {
    static var isInUITest: Bool {
        return ProcessInfo.processInfo.environment["isUITest"] != nil;
    }
}
