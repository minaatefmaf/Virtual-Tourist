//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/13/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import CoreData

class Pin: NSManagedObject{
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Number_Of_Available_Photos = "numberOfAvailablePhotos"
        static let Photos = "photos"
    }
    
    // Promote the simple properties to Core Data attributes.
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var numberOfAvailablePhotos: Int
    @NSManaged var photos: [Photo]
    
    // The standard Core Data init method.
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    // The two argument init method
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Pin" type.
        let entity =  NSEntityDescription.entity(forEntityName: "Pin", in: context)!
        
        // Call an init method that we have inherited from NSManagedObject.
        super.init(entity: entity,insertInto: context)
        
        // Init the properties from the dictionary.
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        // This -ve number indicates that no attempt (with a successful internet connection) was made in order to download the associate photos)
        numberOfAvailablePhotos = -1
    }
    
}
