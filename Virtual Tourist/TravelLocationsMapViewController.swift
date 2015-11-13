//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/11/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomView: UIView!
    
    // Add long press recognizer
    var longPressRecognizer: UILongPressGestureRecognizer? = nil
    // Edit mode: when deleting the pins happen
    var editMode = false
    // To know if the user is still on the same press
    var longPressIsActive = false
    // To hold the array of the pins
    var pins = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the right bar button
        let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editPins")
        self.navigationItem.setRightBarButtonItems([editButton], animated: true)
        
        // Configure tap recognizer
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "handleSingleLongPress:")
        longPressRecognizer?.minimumPressDuration = 0.5
        
        // Restore the last saved region
        restoreMapRegion()
        
        // Fetch our previously saved pins
        pins = fetchAllPins()
        
        // Annotate the map with the previously saved pins
        annotateMapWithPreviouslySavedPins()
        
        // Set the delegate to this view controller
        self.mapView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        addAnotationRecognizer()
        
        // Remove the previous selected annotaion so it can be reselected
        self.mapView.selectedAnnotations.removeAll()
    }
    
    override func viewDidDisappear(animated: Bool) {
        removeAnotationRecognizer()
    }

    func editPins() {
        // Switch to the editing mode
        editMode = true
        
        // Animate rising up the botton view
        UIView.animateWithDuration(0.2, animations: {
            self.mapView.frame.origin.y -= self.bottomView.frame.height
            self.bottomView.frame.origin.y -= self.bottomView.frame.height
        })
        // Change the right bar button to "Done" mode
        let doneButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneEditingPins")
        self.navigationItem.setRightBarButtonItem(doneButton, animated: true)
        
    }
    
    func doneEditingPins() {
        // Switch back to the normal mode
        editMode = false
        
        // Animate falling down the botton view
        UIView.animateWithDuration(0.2, animations: {
            self.mapView.frame.origin.y += self.bottomView.frame.height
            self.bottomView.frame.origin.y += self.bottomView.frame.height
        })
        // Change the right bar button to "Edit" mode again
        let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editPins")
        self.navigationItem.setRightBarButtonItem(editButton, animated: true)
    }
    
    func annotateMapWithPreviouslySavedPins() {
        // Create MKPointAnnotation for each dictionary in "locations".
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            
            // The latitude and longitude are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            
            // Create the annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            // Add the annotations to the map.
            self.mapView.addAnnotations(annotations)
        }

    }
    
    func searchForPin(arrayOfPins: [Pin], coordinate: CLLocationCoordinate2D) -> Pin? {
        for pin in arrayOfPins {
            if pin.latitude == coordinate.latitude {
                if pin.longitude == coordinate.longitude {
                    return pin
                }
            }
        }
        return nil
    }
    
    // MARK: - Core Data Convenience.
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func fetchAllPins() -> [Pin] {
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch _ {
            return [Pin]()
        }
    }

    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = MKPinAnnotationView.redPinColor()
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // Navigate to the Photo Album View if in normal mode
        if !editMode {
            let photoAlbumController = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
            
            // Change the back bar button title in the photo album view
            let backItem = UIBarButtonItem()
            backItem.title = "OK"
            navigationItem.backBarButtonItem = backItem
            
            self.navigationController!.pushViewController(photoAlbumController, animated: true)
        } else {
            // In the edit mode: Remove the pin:
            // remove the pin from the map
            let annotationToBeRemoved = view.annotation!
            self.mapView.removeAnnotation(annotationToBeRemoved)
            
            let pinToBeRemoved = searchForPin(pins, coordinate: annotationToBeRemoved.coordinate)!

            // Remove the pin from the context
            sharedContext.deleteObject(pinToBeRemoved)
            
            // Save the context
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Save the current region
        saveMapRegion()
    }
    
    // MARK: - Save the map region helpers
    
    // A convenient property
    var filePath: String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first! as NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }

    func saveMapRegion() {
         // Place the "center" and "span" of the map into a dictionary
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion() {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            // Restore the center
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            // Restore the span
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            // Restore the region
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(savedRegion, animated: false)
        }
    }
    
    // MARK: - Gesture recognizer convenience
    
    func addAnotationRecognizer() {
        view.addGestureRecognizer(longPressRecognizer!)
    }
    
    func removeAnotationRecognizer() {
        view.removeGestureRecognizer(longPressRecognizer!)
    }
    
    func handleSingleLongPress(recognizer: UITapGestureRecognizer) {
        if editMode {
            // Do nothing here
        } else if !longPressIsActive {
            let tapPostion = recognizer.locationInView(mapView)
            let coordinate = self.mapView.convertPoint(tapPostion, toCoordinateFromView: self.mapView)
            
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude: coordinate.latitude,
                Pin.Keys.Longitude: coordinate.longitude
            ]
            
            // Create a pin in the shared context
            let pinToBeAdded = Pin(dictionary: dictionary, context: sharedContext)
            
            // Add to the pins aray
            self.pins.append(pinToBeAdded)
            
            // Add the annotation to the map
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
            
            // Save the context
            CoreDataStackManager.sharedInstance().saveContext()
            
            // Set longPressIsActive to true so only one annotation is added
            longPressIsActive = true
        }
        
        // Set longPressIsActive to false after the continuous gesture touch is ended
        if (recognizer.state == .Ended) {
            longPressIsActive = false
        }
        
    }

}

