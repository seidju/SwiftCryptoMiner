//
//  StratumJSONRPC.swift
//  SwiftMiner
//
//  Created by Pavel Shatalov on 03.09.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import SwiftyJSON

struct StratumRequest {
    let version: String = "2.0"
    let method: String
    let parameters: Any?
    let id: Int
    
    func serialize() -> [String: Any] {
        var payload = [String: Any]()
        payload["jsonrpc"] = self.version
        payload["method"] = self.method
        if let params = self.parameters {
            payload["params"] = params
        } else {
            payload["params"] = []
        }
        payload["id"] = self.id
        
        return payload
    }
}

