//
//  StratumMethods.swift
//  SwiftMiner
//
//  Created by Pavel Shatalov on 03.09.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//
import Foundation

enum StratumMethods: String {
    case subscribe = "mining.subscribe"
    case authorize = "mining.authorize"
    case submit = "mining.submit"
}

struct Queue {
    static let stratumQueue = DispatchQueue(label: "stratum", qos: .background)
}
