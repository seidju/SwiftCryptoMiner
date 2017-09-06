//
//  StratumParser.swift
//  SwiftMiner
//
//  Created by Pavel Shatalov on 03.09.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import SwiftyJSON

class StratumParser {
    fileprivate let RESPONSE_SEPARATOR = Data(bytes: [0x0A])
    
    func parse(data: Data) -> Any? {
        if let json = JSON(data).dictionary {
            print(json)
            if let method = json["method"]?.string {
                guard let params = json["params"]?.arrayObject else { return nil }
                let request = StratumRequest(method: method, parameters: params, id: 3)
                return request
            } else if let result = json["result"]?.arrayObject {
                guard let id = json["id"]?.int else { return nil }
                if id == 1 {
                    let subscribeResult = SubscribeResult.parseWithResult(result)
                    return subscribeResult
                }
            }
        }
        return nil
    }    
}

