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
    // To know the toggle state
    var instantaneouslyDownloadingFeature = false
    // To hold the array of the pins
    var pins = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Restore the last toggle state
        restoreToggleState()
        
        // Add the right bar buttons
        if instantaneouslyDownloadingFeature == false {
            let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(TravelLocationsMapViewController.editPins))
            let toggleButton: UIBarButtonItem = UIBarButtonItem(title: "N/A->Ins.", style: .plain, target: self, action: #selector(TravelLocationsMapViewController.toggleTheInstantaneouslyDownloadingFeature))
            self.navigationItem.setRightBarButtonItems([editButton, toggleButton], animated: true)
        } else {
            let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(TravelLocationsMapViewController.editPins))
            let toggleButton: UIBarButtonItem = UIBarButtonItem(title: "Ins.->N/A", style: .plain, target: self, action: #selector(TravelLocationsMapViewController.toggleTheInstantaneouslyDownloadingFeature))
            self.navigationItem.setRightBarButtonItems([editButton, toggleButton], animated: true)
        }

        // Configure tap recognizer
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapViewController.handleSingleLongPress(_:)))
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
    
    override func viewWillAppear(_ animated: Bool) {
        addAnotationRecognizer()
        
        // Remove the previous selected annotaion so it can be reselected
        self.mapView.selectedAnnotations.removeAll()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeAnotationRecognizer()
    }

    func editPins() {
        // Switch to the editing mode
        editMode = true
        
        // Animate rising up the botton view
        UIView.animate(withDuration: 0.2, animations: {
            self.mapView.frame.origin.y -= self.bottomView.frame.height
            self.bottomView.frame.origin.y -= self.bottomView.frame.height
        })
        // Change the right bar button to "Done" mode
        let doneButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(TravelLocationsMapViewController.doneEditingPins))
        self.navigationItem.setRightBarButton(doneButton, animated: true)
        
    }
    
    func toggleTheInstantaneouslyDownloadingFeature() {
        
        if instantaneouslyDownloadingFeature == false {
            // Toggle the instantaneouslyDownloadingFeature
            instantaneouslyDownloadingFeature = true
            
            // Save the new toggle state to the archive
            saveToggleState(instantaneouslyDownloadingFeature)
            
            // Change the right bar buttons
            let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(TravelLocationsMapViewController.editPins))
            let toggleButton: UIBarButtonItem = UIBarButtonItem(title: "Ins.->N/A", style: .plain, target: self, action: #selector(TravelLocationsMapViewController.toggleTheInstantaneouslyDownloadingFeature))
            self.navigationItem.setRightBarButtonItems([editButton, toggleButton], animated: true)
      
            // Let the user know that that means
            displayMessage("Instantaneously downloading feature: Images will be pre-fetched once the pin is dropped if there is an internet connection available.")

        } else {
            // Toggle the instantaneouslyDownloadingFeature
            instantaneouslyDownloadingFeature = false
            
            // Save the new toggle state to the archive
            saveToggleState(instantaneouslyDownloadingFeature)
            
            // Change the right bar buttons
            let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(TravelLocationsMapViewController.editPins))
            let toggleButton: UIBarButtonItem = UIBarButtonItem(title: "N/A->Ins.", style: .plain, target: self, action: #selector(TravelLocationsMapViewController.toggleTheInstantaneouslyDownloadingFeature))
            self.navigationItem.setRightBarButtonItems([editButton, toggleButton], animated: true)
            
            // Let the user know that that means
            displayMessage("N/A: The instantaneously downloading feature is disabled.")
        }
        
    }
    
    func doneEditingPins() {
        // Switch back to the normal mode
        editMode = false
        
        // Animate falling down the botton view
        UIView.animate(withDuration: 0.2, animations: {
            self.mapView.frame.origin.y += self.bottomView.frame.height
            self.bottomView.frame.origin.y += self.bottomView.frame.height
        })
        // Change the right bar button to "Edit" mode again
        let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(TravelLocationsMapViewController.editPins))
        self.navigationItem.setRightBarButton(editButton, animated: true)
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
        
        DispatchQueue.main.async {
            // Add the annotations to the map.
            self.mapView.addAnnotations(annotations)
        }

    }
    
    // Search for a specific pin inside an array of pins
    func searchForPin(_ arrayOfPins: [Pin], coordinate: CLLocationCoordinate2D) -> Pin? {
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
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }()
    
    func fetchAllPins() -> [Pin] {
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.fetch(fetchRequest) as! [Pin]
        } catch _ {
            return [Pin]()
        }
    }

    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Navigate to the Photo Album View if in normal mode
        if !editMode {
            
            // Get the pin to be loaded
            let thePin = searchForPin(pins, coordinate: view.annotation!.coordinate)!
            
            // First check for the availability of an internet connection if the current pin needs to download photos (its numberOfAvailablePhotos is a negative number meaning no previous "successful" attempt to download the pin's photos has been made yet)
            if thePin.numberOfAvailablePhotos < 0 && reachabilityStatus == kNOTREACHABLE {
                displayMessage("The Internet connection appears to be offline.")
                
                // Remove the previous selected annotaion so it can be reselected
                self.mapView.selectedAnnotations.removeAll()
            } else {
                let photoAlbumController = self.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
                
                // Get the pin to be loaded
                photoAlbumController.thePin = thePin
                
                // Change the back bar button title in the photo album view
                let backItem = UIBarButtonItem()
                backItem.title = "OK"
                navigationItem.backBarButtonItem = backItem
                
                // Navigate to the photoAlbumViewController
                self.navigationController!.pushViewController(photoAlbumController, animated: true)
            }
            
        } else {
            // In the edit mode: Remove the pin:
            // remove the pin from the map
            let annotationToBeRemoved = view.annotation!
            self.mapView.removeAnnotation(annotationToBeRemoved)
            
            let pinToBeRemoved = searchForPin(pins, coordinate: annotationToBeRemoved.coordinate)!

            // Remove the pin from the context
            sharedContext.delete(pinToBeRemoved)
            
            // Save the context
            CoreDataStackManager.sharedInstance.saveContext()
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Save the current region
        saveMapRegion()
    }
    
    // MARK: - Save the map region helpers
    
    // A convenient property
    var mapFilePath: String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        return url.appendingPathComponent("mapRegionArchive").path
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
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: mapFilePath)
    }
    
    func restoreMapRegion() {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: mapFilePath) as? [String : AnyObject] {
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

    
    // MARK: - Save the instantaneously downloading feature helpers

    // A convenient property
    var toggleFilePath: String {
        let manager = FileManager.default
        let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
        return url.appendingPathComponent("toggleStateArchive").path
    }
    
    func saveToggleState(_ toggleState: Bool) {
        // Place the toggle state into a dictionary
        let dictionary = [
            "toggleState": toggleState
        ]
        
        // Archive the dictionary into the filePath
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: toggleFilePath)
    }
    
    func restoreToggleState() {
        if let toggleStateDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: toggleFilePath) as? [String : AnyObject] {
            instantaneouslyDownloadingFeature = toggleStateDictionary["toggleState"] as! Bool
        }
    }
    
    // MARK: - Gesture recognizer convenience
    
    func addAnotationRecognizer() {
        view.addGestureRecognizer(longPressRecognizer!)
    }
    
    func removeAnotationRecognizer() {
        view.removeGestureRecognizer(longPressRecognizer!)
    }
    
    func handleSingleLongPress(_ recognizer: UITapGestureRecognizer) {
        if editMode {
            // Do nothing here
        } else if !longPressIsActive {
            let tapPostion = recognizer.location(in: mapView)
            let coordinate = self.mapView.convert(tapPostion, toCoordinateFrom: self.mapView)
            
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude: coordinate.latitude as AnyObject,
                Pin.Keys.Longitude: coordinate.longitude as AnyObject
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
            CoreDataStackManager.sharedInstance.saveContext()
            
            // Set longPressIsActive to true so only one annotation is added
            longPressIsActive = true
            
            // Try to pre-fetch the pin's photos if there's an available internet connection & we're in the instantaneously downloading mode
            // No error will be presented for the user here if there's no internet connection available at the moment
            if reachabilityStatus != kNOTREACHABLE && instantaneouslyDownloadingFeature == true {
                downloadThePhotos(pinToBeAdded)
            }
        }
        
        // Set longPressIsActive to false after the continuous gesture touch is ended
        if (recognizer.state == .ended) {
            longPressIsActive = false
        }
        
    }
    
    // Mark: - Helper functions
    
    func displayMessage(_ messageString: String) {
        // Prepare the Alert view controller with the error message to display
        let alert = UIAlertController(title: "", message: messageString, preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(dismissAction)
        DispatchQueue.main.async(execute: {
            // Display the Alert view controller
            self.present (alert, animated: true, completion: nil)
        })
    }
    
    func downloadThePhotos(_ newPin: Pin) {
        
        // Initiate the dowloading process
        FlikrClient.sharedInstance.getThePhotosFromFlikr(newPin.latitude, longitude: newPin.longitude) { success, numberOfAvailablePhotos, arrayOfURLs, errorString in
            
            if success {
                
                // Save the numberOfAvailablePhotos to the Pin
                if let numberOfAvailablePhotos = numberOfAvailablePhotos{
                    newPin.numberOfAvailablePhotos = numberOfAvailablePhotos
                }
                
                // Save the urls into the photos array associated with the pin
                for url in arrayOfURLs {
                    
                    // Extract the last component of the url to be the file name on disc
                    let fileNameOnDisc = URL(string: url)?.lastPathComponent
                    
                    let dictionary: [String : AnyObject] = [
                        Photo.Keys.PhotoPath: url as AnyObject,
                        Photo.Keys.PhotoNameOnDisc: fileNameOnDisc! as AnyObject
                    ]
                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                    photo.pin = newPin
                }
                CoreDataStackManager.sharedInstance.saveContext()
                
                // Try to prefetch the photos for this pin
                self.prefetchThePhotos(newPin)
                
            }
            
        }
        
    }
    
    func prefetchThePhotos(_ newPin: Pin) {
        
        for photo in newPin.photos {
            
            // Start the task that will eventually download the image
            FlikrClient.sharedInstance.taskForImage(photo.photoPath!) { imageData, error in
                
                if let data = imageData {
                    // Create the image
                    photo.photoImage = UIImage(data: data)
                }
                
            }
            
        }
        
    }

}

