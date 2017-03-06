//
//  FlikrConvenience.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/14/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import Foundation

// MARK: - Convenient Resource Methods

extension FlikrClient {
    
    typealias CompletionHander = (_ success: Bool, _ numberOfAvailablePhotos: Int?, _ arrayOfURLs: [String], _ errorString: String?) -> Void
    
    func getThePhotosFromFlikr(_ latitude: Double, longitude: Double, completionHandler: @escaping CompletionHander) {
        
        // Specify parameters, methods
        let methodArguments = [
            "method": MethodArguments.METHOD_NAME,
            "api_key": Constants.API_KEY,
            "bbox": createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": MethodArguments.SAFE_SEARCH,
            "extras": MethodArguments.EXTRAS,
            "format": MethodArguments.DATA_FORMAT,
            "nojsoncallback": MethodArguments.NO_JSON_CALLBACK
        ]
        
        // The photos urls
        let arrayOfURLs = [String]()
        
        // Make the request
        taskForResource(methodArguments as [String : AnyObject]) { JSONResult, error in
           
            // GUARD: Did Flickr return an error?
            guard let stat = JSONResult?["stat"] as? String, stat == "ok" else {
                let errorString = "Flickr API returned an error. See error code and message in \(JSONResult)"
                completionHandler(false, nil, arrayOfURLs, errorString)
                print("Flickr API returned an error. See error code and message in \(JSONResult)")
                return
            }
            
            // GUARD: Is "photos" key in our result?
            guard let photosDictionary = JSONResult?["photos"] as? NSDictionary else {
                let errorString = "Cannot find keys 'photos' in \(JSONResult)"
                completionHandler(false, nil, arrayOfURLs, errorString)
                print("Cannot find keys 'photos' in \(JSONResult)")
                return
            }
            
            // GUARD: Is "pages" key in the photosDictionary?
            guard let totalPages = photosDictionary["pages"] as? Int else {
                let errorString = "Cannot find key 'pages' in \(photosDictionary)"
                completionHandler(false, nil, arrayOfURLs, errorString)
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            
            // Pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageFromFlickrBySearchWithPage(methodArguments as [String : AnyObject], pageNumber: randomPage, completionHandler: completionHandler)
        }
    }
    
    func getImageFromFlickrBySearchWithPage(_ methodArguments: [String : AnyObject], pageNumber: Int, completionHandler: @escaping CompletionHander) {
       
        // Add the page to the method's arguments
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber as AnyObject?
        
        // The photos urls
        var arrayOfURLs = [String]()
        
        // Make the request
        taskForResource(methodArguments) { JSONResult, error in
            
            if let error = error {
                completionHandler(false, nil, arrayOfURLs, error.localizedDescription)
                return
            }
            
            // GUARD: Did Flickr return an error (stat != ok)?
            guard let stat = JSONResult?["stat"] as? String, stat == "ok" else {
                let errorString = "Flickr API returned an error. See error code and message in \(JSONResult)"
                completionHandler(false, nil, arrayOfURLs, errorString)
                print("Flickr API returned an error. See error code and message in \(JSONResult)")
                return
            }
            
            // GUARD: Is the "photos" key in our result?
            guard let photosDictionary = JSONResult?["photos"] as? NSDictionary else {
                let errorString = "Cannot find key 'photos' in \(JSONResult)"
                completionHandler(false, nil, arrayOfURLs, errorString)
                print("Cannot find key 'photos' in \(JSONResult)")
                return
            }
            
            // GUARD: Is the "total" key in photosDictionary?
            guard let totalPhotosVal = (photosDictionary["total"] as? NSString)?.integerValue else {
                let errorString = "Cannot find key 'total' in \(photosDictionary)"
                completionHandler(false, nil, arrayOfURLs, errorString)
                print("Cannot find key 'total' in \(photosDictionary)")
                return
            }
            
            if totalPhotosVal > 0 {
                
                // GUARD: Is the "photo" key in photosDictionary?
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    let errorString = "Cannot find key 'photo' in \(photosDictionary)"
                    completionHandler(false, nil, arrayOfURLs, errorString)
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                if totalPhotosVal <= 21 {
                    arrayOfURLs = self.getAllPhotosWeHave(photosArray)
                    completionHandler(true, totalPhotosVal, arrayOfURLs, nil)
                } else {
                    arrayOfURLs = self.getRandom21Photos(photosArray)
                    completionHandler(true, totalPhotosVal, arrayOfURLs, nil)
                }
                
            } else {
                // Return "Pin has no photos"
                completionHandler(true, 0, arrayOfURLs, nil)
            }
            
        }
        
    }
    
    
    // Mark: Helper methods for filtering the urls we need
    
    func getAllPhotosWeHave(_ photosArray: [[String : AnyObject]]) -> [String] {
        
        var arrayOfURLs = [String]()
        
        for _ in photosArray {
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
            let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
            
            // GUARD: Does our photo have a key for 'url_m'?
            guard let imageUrlString = photoDictionary["url_m"] as? String else {
                // Skip this turn
                continue
            }
            
            arrayOfURLs.append(imageUrlString)
        }
        
        return arrayOfURLs
    }
    
    func getRandom21Photos(_ photosArray: [[String : AnyObject]]) -> [String] {
        
        var arrayOfURLs = [String]()
        
        for _ in photosArray {
            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
            let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
            
            // GUARD: Does our photo have a key for 'url_m'?
            guard let imageUrlString = photoDictionary["url_m"] as? String else {
                // Skip this turn
                continue
            }
            
            arrayOfURLs.append(imageUrlString)
            
            if arrayOfURLs.count > 20 {
                // If we already have our 21 photo
                break
            }
            
        }
        
        return arrayOfURLs
    }
    
    // MARK: Lat/Lon Manipulation
    
    func createBoundingBoxString(_ latitude: Double, longitude: Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BoundingBox.BOUNDING_BOX_HALF_WIDTH, BoundingBox.LON_MIN)
        let bottom_left_lat = max(latitude - BoundingBox.BOUNDING_BOX_HALF_HEIGHT, BoundingBox.LAT_MIN)
        let top_right_lon = min(longitude + BoundingBox.BOUNDING_BOX_HALF_HEIGHT, BoundingBox.LON_MAX)
        let top_right_lat = min(latitude + BoundingBox.BOUNDING_BOX_HALF_HEIGHT, BoundingBox.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func getLatLonString(_ latitude: Double, longitude: Double) -> String {
        return "(\(latitude), \(longitude))"
    }
    
}
