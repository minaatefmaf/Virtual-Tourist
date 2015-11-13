//
//  FlikrClient.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/13/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import Foundation

class FlikrClient: NSObject {
    
    // Shared session
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlikrClient {
        
        struct Singleton {
            static var sharedInstance = FlikrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }

}