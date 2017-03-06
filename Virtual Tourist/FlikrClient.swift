//
//  FlikrClient.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/13/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import Foundation

class FlikrClient: NSObject {
    
    // Shared Instance
    static let sharedInstance = FlikrClient()
    
    // Shared Image Cache
    static let imageCache = ImageCache()
    
    // Shared session
    var session: URLSession
    
    override init() {
        session = URLSession.shared
        super.init()
    }
    
    
    // MARK: - All purpose task method for data
    
    func taskForResource(_ methodArguments: [String : AnyObject], completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        var mutableParameters = methodArguments
        
        // Add in the API Key
        mutableParameters["api_key"] = Constants.API_KEY as AnyObject?
        
        // Build the URL
        let urlString = Constants.BASE_URL_SECURE + FlikrClient.escapedParameters(mutableParameters)
        let url = URL(string: urlString)!
        let request = URLRequest(url: url)
        
        // Make the request
        let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in
            
            // GUARD: Was there an error?
            guard (downloadError == nil) else {
                completionHandler(nil, downloadError as NSError?)
                return
            }
            
            // GUARD: Did we get a successful 2XX response?
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? HTTPURLResponse {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response! Status code: '\(response.statusCode)'"]
                    completionHandler(nil, NSError(domain: "FlikrJSONWithCompletionHandler", code: 1, userInfo: userInfo))
                } else if let response = response {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response! Response: '\(response)'"]
                    completionHandler(nil, NSError(domain: "FlikrJSONWithCompletionHandler", code: 1, userInfo: userInfo))
                } else {
                    let userInfo = [NSLocalizedDescriptionKey: "Your request returned an invalid response!"]
                    completionHandler(nil, NSError(domain: "FlikrJSONWithCompletionHandler", code: 1, userInfo: userInfo))
                }
                return
            }
            
            // GUARD: Was there any data returned?
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey: "No data was returned by the request!"]
                completionHandler(nil, NSError(domain: "FlikrJSONWithCompletionHandler", code: 1, userInfo: userInfo))
                return
            }
            
            // Parse the data and use the it (happens in completion handler)
            FlikrClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
        }) 
        
        task.resume()
        
        return task
    }
    
    
    // MARK: - All purpose task method for images
    
    func taskForImage(_ filePath: String, completionHandler: @escaping (_ imageData: Data?, _ error: NSError?) ->  Void) -> URLSessionTask {
        
        let url = URL(string: filePath)!
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in
            
            if let error = downloadError {
                completionHandler(nil, error as NSError?)
            } else {
                completionHandler(data, nil)
            }
        }) 
        
        task.resume()
        
        return task
    }

    
    // MARK: - Helpers
    
    // Parsing the JSON
    class func parseJSONWithCompletionHandler(_ data: Data, completionHandler: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(nil, error)
        } else {
            completionHandler(parsedResult, nil)
        }
    }
    
    // URL Encoding a dictionary into a parameter string
    class func escapedParameters(_ parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            // Append it
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
}
