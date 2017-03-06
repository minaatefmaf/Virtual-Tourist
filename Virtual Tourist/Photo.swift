//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/13/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    
    struct Keys {
        static let PhotoPath = "photo_path"
        static let PhotoNameOnDisc = "photo_name_on_disc"
    }
    
    // Promote the simple properties to Core Data attributes.
    @NSManaged var photoPath: String?
    @NSManaged var photoNameOnDisc: String?
    @NSManaged var pin: Pin?
    
    // The standard Core Data init method.
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    // The two argument init method
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Pin" type.
        let entity =  NSEntityDescription.entity(forEntityName: "Photo", in: context)!
        
        // Call an init method that we have inherited from NSManagedObject.
        super.init(entity: entity,insertInto: context)
        
        // Init the properties from the dictionary.
        photoPath = dictionary[Keys.PhotoPath] as? String
        photoNameOnDisc = dictionary[Keys.PhotoNameOnDisc] as? String
        
    }

    var photoImage: UIImage? {
        
        get {
            return FlikrClient.imageCache.imageWithIdentifier(photoNameOnDisc)
        }
        
        set {
            FlikrClient.imageCache.storeImage(newValue, withIdentifier: photoNameOnDisc!)
        }
    }

    override func prepareForDeletion() {
        FlikrClient.imageCache.deleteImage(withIdentifier: photoNameOnDisc!)
    }
    
}
