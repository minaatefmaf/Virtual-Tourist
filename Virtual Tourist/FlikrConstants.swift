//
//  FlikrConstants.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/13/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import Foundation

extension FlikrClient {
    
    // MARK: - Constants
    struct Constants {
        
        // MARK: Flikr API key
        static let API_KEY: String = "ENTER_A_FLIKR_API_KEY"
        
        // MARK: URL
        static let BASE_URL_SECURE: String = "https://api.flickr.com/services/rest/"
        
    }
    
    
    // MARK: - Method Arguments
    struct MethodArguments {
        
        static let METHOD_NAME = "flickr.photos.search"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        
    }
    
    
    // MARK: - Bounding Box Stuff
    struct BoundingBox {
        
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        
    }
    
    // MARK: - Resources
    struct Resources {
    
    }
    
    
    // MARK: - Keys
    struct Keys {
        static let ErrorStatusMessage = "status_message"
    }
    
}