//
//  SubscribeResult.swift
//  SwiftMiner
//
//  Created by Pavel Shatalov on 05.09.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import Foundation

struct SubscribedNotification {
    var name: String
    var hash: String
}

class SubscribeResult {
    var subscribedNotifications: [SubscribedNotification] = []
    var extraNonce1: String!
    var extraNonce2Size: Int!
    
    class func parseWithResult(_ resultObject: [Any]) -> SubscribeResult? {
        // if the array count != 3, then it cannot be a subscribe result
        let result = resultObject as [AnyObject]
        if result.count != 3 { return nil }
        let subscribeResult = SubscribeResult()
        // parse the data in the array (subscribed services(name, hash), extraNonce1, extraNonce2Size)
        let subscribedNotificationsArray = result[0] as! [AnyObject]

        for subscribedNotification in subscribedNotificationsArray {
            let name = subscribedNotification[0] as! String
            let hash = subscribedNotification[1] as! String
            subscribeResult.subscribedNotifications.append(SubscribedNotification(name: name, hash: hash))
        }
            
        subscribeResult.extraNonce1 = result[1] as! String
        subscribeResult.extraNonce2Size = result[2] as? Int
        return subscribeResult
    }
}
