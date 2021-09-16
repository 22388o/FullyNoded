//
//  BlockchainInfo.swift
//  BitSense
//
//  Created by Peter on 27/06/20.
//  Copyright © 2020 Fontaine. All rights reserved.
//

import Foundation

/*
 {                                         (json object)
   "chain" : "str",                        (string) current network name (main, test, regtest)
   "blocks" : n,                           (numeric) the height of the most-work fully-validated chain. The genesis block has height 0
   "headers" : n,                          (numeric) the current number of headers we have validated
   "bestblockhash" : "str",                (string) the hash of the currently best block
   "difficulty" : n,                       (numeric) the current difficulty
   "mediantime" : n,                       (numeric) median time for the current best block
   "verificationprogress" : n,             (numeric) estimate of verification progress [0..1]
   "initialblockdownload" : true|false,    (boolean) (debug information) estimate of whether this node is in Initial Block Download mode
   "chainwork" : "hex",                    (string) total amount of work in active chain, in hexadecimal
   "size_on_disk" : n,                     (numeric) the estimated size of the block and undo files on disk
   "pruned" : true|false,                  (boolean) if the blocks are subject to pruning
   "pruneheight" : n,                      (numeric) lowest-height complete block stored (only present if pruning is enabled)
   "automatic_pruning" : true|false,       (boolean) whether automatic pruning is enabled (only present if pruning is enabled)
   "prune_target_size" : n,                (numeric) the target size used by pruning (only present if automatic pruning is enabled)
   "softforks" : {                         (json object) status of softforks
     "xxxx" : {                            (json object) name of the softfork
       "type" : "str",                     (string) one of "buried", "bip9"
       "bip9" : {                          (json object) status of bip9 softforks (only for "bip9" type)
         "status" : "str",                 (string) one of "defined", "started", "locked_in", "active", "failed"
         "bit" : n,                        (numeric) the bit (0-28) in the block version field used to signal this softfork (only for "started" status)
         "start_time" : xxx,               (numeric) the minimum median time past of a block at which the bit gains its meaning
         "timeout" : xxx,                  (numeric) the median time past of a block at which the deployment is considered failed if not yet locked in
         "since" : n,                      (numeric) height of the first block to which the status applies
         "min_activation_height" : n,      (numeric) minimum height of blocks for which the rules may be enforced
         "statistics" : {                  (json object) numeric statistics about BIP9 signalling for a softfork (only for "started" status)
           "period" : n,                   (numeric) the length in blocks of the BIP9 signalling period
           "threshold" : n,                (numeric) the number of blocks with the version bit set required to activate the feature
           "elapsed" : n,                  (numeric) the number of blocks elapsed since the beginning of the current period
           "count" : n,                    (numeric) the number of blocks with the version bit set in the current period
           "possible" : true|false         (boolean) returns false if there are not enough blocks left in this period to pass activation threshold
         }
       },
       "height" : n,                       (numeric) height of the first block which the rules are or will be enforced (only for "buried" type, or "bip9" type with "active" status)
       "active" : true|false               (boolean) true if the rules are enforced for the mempool and the next block
     },
     ...
   },
   "warnings" : "str"                      (string) any network and blockchain warnings
 }
 */

public struct BlockchainInfo: CustomStringConvertible {
    
    let difficulty:Int
    let network:String
    let blockheight:Int
    let size_on_disk:Int
    let progress:String
    let pruned:Bool
    let verificationprogress:Double
    let pruneheight:Int
    let chain:String
    let blocks:Int
    let initialblockdownload:Bool
    
    init(_ dictionary: [String: Any]) {
        network = dictionary["chain"] as? String ?? ""
        blockheight = dictionary["blocks"] as? Int ?? 0
        UserDefaults.standard.set(blockheight, forKey: "blockheight")
        difficulty = Int(dictionary["difficulty"] as! Double)
        size_on_disk = Int(dictionary["size_on_disk"] as! UInt64)
        progress = dictionary["progress"] as? String ?? ""
        pruned = dictionary["pruned"] as? Bool ?? false
        verificationprogress = dictionary["verificationprogress"] as? Double ?? 0.0
        pruneheight = dictionary["pruneheight"] as? Int ?? 0
        chain = dictionary["chain"] as? String ?? ""
        UserDefaults.standard.set(chain, forKey: "chain")
        blocks = dictionary["blocks"] as? Int ?? 0
        initialblockdownload = dictionary["initialblockdownload"] as? Bool ?? false
    }
    
    public var description: String {
        return ""
    }
}
