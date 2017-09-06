//
//  StratumClient.swift
//  SwiftMiner
//
//  Created by Pavel Shatalov on 03.09.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import CocoaAsyncSocket
import SwiftyJSON
import RxSwift

class StratumClient: NSObject {
    
    let host: String
    let port: Int
    
    let login = "login"
    let password = "password"
    
    var newJob: Observable<JobParameters> {
        return self.newJobSubject.asObservable()
    }
    
    var newSubscribe: Observable<SubscribeResult> {
        return self.subscribeSubject.asObservable()
    }
    
    fileprivate var socket: GCDAsyncSocket!
    fileprivate let TERMINATING_BYTE: UInt8 = 0x0A
    fileprivate let parser = StratumParser()
    
    fileprivate var newJobSubject = PublishSubject<JobParameters>()
    fileprivate var subscribeSubject = PublishSubject<SubscribeResult>()
    
    
    init(host: String, port: Int) {
        self.host = host
        self.port = port
        super.init()
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: Queue.stratumQueue)
    }
    
    func connect() {
        do {
            try self.socket.connect(toHost: self.host, onPort: UInt16(self.port))
        } catch {
            print("Connection error: \(error)")
        }
    }
    
    func subscribe() {
        let subscribe = StratumRequest(method: StratumMethods.subscribe.rawValue, parameters: nil, id: 1)
        self.sendRequest(request: subscribe)
    }
    
    
    func authorize() {
        let authorize = StratumRequest(method: StratumMethods.authorize.rawValue, parameters: [login, password], id: 2)
        self.sendRequest(request: authorize)
    }
    
    func submitShare(miner: String, jobId: String, extraNonce2: String, nTime: String, nonce: String) {
        let params = [miner, jobId, extraNonce2, nTime, nonce]
        let request = StratumRequest(method: StratumMethods.submit.rawValue, parameters: params, id: 4)
        self.sendRequest(request: request)
    }
    
    
    fileprivate func sendRequest(request: StratumRequest) {
        let dataDict = request.serialize()
        print(dataDict)
        do {
            var data = try JSON(dataDict).rawData()
            data.append(TERMINATING_BYTE)
            self.socket.write(data, withTimeout: -1, tag: 1)
            self.socket.readData(withTimeout: -1, tag: 2)
        } catch {
            print("Serialization error: \(error)")
            fatalError()
        }
        
    }
    
    fileprivate func parseData(data: Data) {
        guard let response = self.parser.parse(data: data) else { return }
        if let request = response as? StratumRequest {
            if let newJob = JobParameters.parseWithRequest(request: request) {
                self.newJobSubject.onNext(newJob)
            }
        } else if let result = response as? SubscribeResult {
            self.subscribeSubject.onNext(result)
            self.subscribeSubject.onCompleted()
            
        }
    }
}


extension StratumClient: GCDAsyncSocketDelegate {
    
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("***********************CONNECTED TO SOCKET*************************")
        print("*********************** \(host), \(port)*************************")
        self.subscribe()
        self.authorize()
    }
    
    func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("**************************DID READ DATA :\(data)***********************)")
        sock.readData(withTimeout: -1, tag: 2)
        self.parseData(data: data)
    }

    
    func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        print("***********************DISCONNECTED FROM SOCKET WITH ERROR \(err)*************************\n"
    }
    
   
}
