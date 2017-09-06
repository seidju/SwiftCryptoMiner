//
//  JobParameters.swift
//  SwiftMiner
//
//  Created by Pavel Shatalov on 03.09.17.
//  Copyright © 2017 Pavel Shatalov. All rights reserved.
//

import Foundation

class JobParameters {
    var jobId: String!
    var previousHash: String!
    var coinb1: String!
    var coinb2: String!
    var merkleBranch: [String] = []
    var version: String!
    var nbits: String!
    var ntime: String!
    var cleanJobs: Bool!
    
    class func parseWithRequest(request: StratumRequest) -> JobParameters? {
        guard let params = request.parameters as? [Any] else { return nil }
        guard params.count == 9 else { return nil }
        let job = JobParameters()
        job.jobId = params[0] as! String
        job.previousHash = params[1] as! String
        job.coinb1 = params[2] as! String
        job.coinb2 = params[3] as! String
        job.merkleBranch = params[4] as! [String]
        job.version = params[5] as! String
        job.nbits = params[6] as! String
        job.ntime = params[7] as! String
        job.cleanJobs = params[8] as! Bool
        return job
    }
}

