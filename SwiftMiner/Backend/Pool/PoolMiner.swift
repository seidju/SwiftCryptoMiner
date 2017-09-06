//
//  PoolMiner.swift
//  SwiftMiner
//
//  Created by Pavel Shatalov on 05.09.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import RxSwift
import CryptoSwift


class PoolMiner {
    
    let stratumClient: StratumClient
    var subscribeResult: SubscribeResult?
    let bag = DisposeBag()
    
    fileprivate var currentlyMining = false
    fileprivate var cancelMining = false
    init(stratumClient: StratumClient) {
        self.stratumClient = stratumClient
        self.subscribeToResult()
        self.subscribeToNewJob()
    }
    
    
    
    func subscribeToResult() {
        self.stratumClient.newSubscribe
            .subscribe(onNext: { result in
                self.subscribeResult = result
            }).addDisposableTo(self.bag)
    }
    
    
    func subscribeToNewJob() {
        self.stratumClient.newJob
            .subscribe(onNext: { job in
                if self.currentlyMining {
                    self.cancelMining = true
                    while self.currentlyMining {}
                }
                self.startMining(job)
            }).addDisposableTo(self.bag)
    }
    
    
    func stringToBytes(_ string: String) -> [UInt8]? {
        let length = string.characters.count
        if length & 1 != 0 {
            return nil
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = string.startIndex
        for _ in 0..<length/2 {
            let nextIndex = string.index(index, offsetBy: 2)
            if let b = UInt8(string[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        return bytes
    }

    
    func doubleSHA256(data: Data) -> Data{
        let hash1 = data.sha256()
        let hash2 = hash1.sha256()
        return hash2
    }
    
    func reverseInChunks(data: Data, chunkSize: Int) -> Data {
        var reversedArray = data.bytes
        var i = 0
        while i < data.count{
            for j in 1...chunkSize {
                reversedArray[i + chunkSize - j] = data.bytes[i + j - 1]
            }
            i += chunkSize
        }
        
        //print(data.bytes)
        //print(reversedArray)
        let data = Data(bytes: reversedArray)
        return data
    }

    
    
//FIXME: 
//There's a seriuos memory leaking, memory also need to swotch from NSData to Data
    func startMining(_ job: JobParameters) {
        autoreleasepool {
        if let subscribeResultUnwrapped = self.subscribeResult {
            // setup
            self.currentlyMining = true
            var lastTime = Date()
            var hashesDone: Double = 0
            var extraNonce2: UInt32 = 0
            
            // mining loop
            while extraNonce2 < 0xFFFFFFFF {
                // cancel the mining job if requested
                if self.cancelMining {
                    self.cancelMining = false
                    self.currentlyMining = false
                    break
                }
                
                // get extranonce2
                let extraNonce2String = String(format: "%08x", extraNonce2)
                
                // create coinbase, hash it
                let coinbase = NSData(hexString: job.coinb1 + subscribeResultUnwrapped.extraNonce1 + extraNonce2String + job.coinb2)
                let coinbaseHash = Cryptography.doubleSha256HashData(coinbase!.bytes, length: UInt32(coinbase!.length))! as NSData
                
                // calculate merkle root
                var merkleRoot = coinbaseHash
                for h in job.merkleBranch {
                    let merkleRootDataBlock = DataBlock(rawData: merkleRoot)
                    merkleRootDataBlock.addSegment(data: NSData(hexString: h))
                    let data = merkleRootDataBlock.rawData
                    merkleRoot = Cryptography.doubleSha256HashData((data as NSData).bytes, length: UInt32(data.length))! as NSData
                }
                
                // create block header
                let blockHeaderDataBlock = DataBlock()
                blockHeaderDataBlock.addSegment(data: NSData(hexString: job.version)! as NSData)
                blockHeaderDataBlock.addSegment(data: NSData(hexString: job.previousHash)! as NSData)
                blockHeaderDataBlock.addSegment(data: merkleRoot.reverse() as NSData)
                blockHeaderDataBlock.addSegment(data: NSData(hexString: job.ntime)! as NSData)
                blockHeaderDataBlock.addSegment(data: NSData(hexString: job.nbits)! as NSData)
                blockHeaderDataBlock.addSegment(data: NSData(hexString: "00000000"))
                blockHeaderDataBlock.addSegment(data: NSData(hexString: "000000800000000000000000000000000000000000000000000000000000000000000000000000000000000080020000"))
                
                // get the raw data, hash it
                let blockHeaderRawData = blockHeaderDataBlock.rawData
                let hash = Cryptography.doubleSha256HashData((blockHeaderRawData as NSData).bytes, length: UInt32(blockHeaderRawData.length))! as NSData
                
                #if DEBUG
                    print("coinbase: \(coinbase)")
                    print("coinbase hash: \(coinbaseHash)")
                    print("merkle root: \(merkleRoot)")
                    print("block header: \(blockHeaderRawData)")
                    print("block header hash: \(hash)")
                #endif
                
                // see if the block header meets difficulty
                let leading = hash.range(of: Data(bytes: [0,0,0,0]), options: [.anchored], in: NSMakeRange(0, hash.length)).length != 0
                let trailing = hash.range(of: Data(bytes: [0, 0,0,0]), options: [.anchored, .backwards], in: NSMakeRange(0, hash.length)).length != 0

                if leading || trailing {
                    // if so, print the has and submit it
                    self.stratumClient.submitShare(miner: "ios.SwiftWorker",  jobId: job.jobId, extraNonce2: String(format: "%08x", extraNonce2), nTime: job.ntime, nonce: subscribeResultUnwrapped.extraNonce1)
                }
                
                // increment the amount of hashes we've done
                hashesDone += 1
                // get the time it's been since last calculated
                let interval = Date().timeIntervalSince(lastTime)
                if interval > 10 {
                    // if greate than 10 seconds, recalculate
                    let hashesPerSecond = hashesDone / interval
                    print("hashes per second: \(hashesPerSecond)")
                    
                    self.stratumClient.submitShare(miner: "ios.seidju",  jobId: job.jobId, extraNonce2: String(format: "%08x", extraNonce2), nTime: job.ntime, nonce: subscribeResultUnwrapped.extraNonce1)

                    // reset hashes done and the last calculated time
                    hashesDone = 0
                    lastTime = Date()
                }
            extraNonce2 += 1
            }
        }
        
        print("not solved...")
        }
    }
}
