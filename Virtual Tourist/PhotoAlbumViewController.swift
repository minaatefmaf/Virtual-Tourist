//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/12/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editingButton: UIButton!
    
    // The pin to display (from TravelLocationsMapViewController)
    var thePin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate to this view controller
        self.mapView.delegate = self
        
        // Annotate the map with the pin
        annotateTheLocationOnMap()
        
        // Configure the UI
        configureUI()
    }
    
    func annotateTheLocationOnMap() {
        // Get the location on the map
        let coordinate = CLLocationCoordinate2D(latitude: thePin.latitude, longitude: thePin.longitude)
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(coordinate, span)
        mapView.setRegion(region, animated: true)
        
        // Annotate the location
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: thePin.latitude, longitude: thePin.longitude)
        mapView.addAnnotation(annotation)
    }
        
    func configureUI() {
        // Prepare the map view
        mapView.scrollEnabled = false
        mapView.zoomEnabled = false
    }
    
    func downloadThePhotos() {
        FlikrClient.sharedInstance().getThePhotosFromFlikr(thePin.latitude, longitude: thePin.longitude) { success, numberOfAvailablePhotos, arrayOfURLs, errorString in
            
            if success {
                
                // Save the numberOfAvailablePhotos to the Pin
                if let numberOfAvailablePhotos = numberOfAvailablePhotos{
                    self.thePin.numberOfAvailablePhotos = numberOfAvailablePhotos
                }
                
                // Save the urls into the photos array associated with the pin
                for url in arrayOfURLs {
                    let dictionary: [String : AnyObject] = [
                        Photo.Keys.PhotoPath: url
                    ]
                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                    photo.pin = self.thePin
                }
                CoreDataStackManager.sharedInstance().saveContext()
                
            } else {
                // Display an alert with the error for the user
                self.displayError(errorString)
                dispatch_async(dispatch_get_main_queue()) {
                    // TODO: Do stuff here regards to the UI
                }
                
            }
            
        }
    }
    
    func displayError(errorString: String?) {
        if let errorString = errorString {
            // Prepare the Alert view controller with the error message to display
            let alert = UIAlertController(title: "", message: errorString, preferredStyle: .Alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(dismissAction)
            dispatch_async(dispatch_get_main_queue(), {
                // Display the Alert view controller
                self.presentViewController (alert, animated: true, completion: nil)
            })
        }
    }
    
    
    // MARK: - Core Data Convenience.
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
}