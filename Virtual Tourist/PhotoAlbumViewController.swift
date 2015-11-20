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

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editingButton: UIButton!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var noPinsLabel: UILabel!
    
    // The pin to display (from TravelLocationsMapViewController)
    var thePin: Pin!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected".
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes; keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate to this view controller
        self.mapView.delegate = self
        
        // Annotate the map with the pin
        annotateTheLocationOnMap()
        
        // Configure the UI
        configureUI()
        
        // Perform the fetch
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Error performing initial fetch: \(error)")
        }
        
        //Set the delegate to this view controller
        fetchedResultsController.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        /* If numberOfAvailablePhotos is -ve: no previous attempt was made to download this pin's photos.
           If numberOfAvailablePhotos == 0: found no photos associated with this pin if the first attempt (with a successful internet connection) was made*/
        if thePin.numberOfAvailablePhotos < 0 {
            downloadThePhotos()
        } else if thePin.numberOfAvailablePhotos == 0 {
            noPinsLabel.hidden = false
        }
    }
    
    // Layout the collection view
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let width = floor(self.collectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        collectionView.collectionViewLayout = layout
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
        
        // Hide the noPinsLabel
        noPinsLabel.hidden = true
    }
    
    func downloadThePhotos() {
        
        // Disable the bottom button
        self.bottomButton.enabled = false
        
        // Initiate the dowloading process
        FlikrClient.sharedInstance().getThePhotosFromFlikr(thePin.latitude, longitude: thePin.longitude) { success, numberOfAvailablePhotos, arrayOfURLs, errorString in
            
            if success {
                
                // Save the numberOfAvailablePhotos to the Pin
                if let numberOfAvailablePhotos = numberOfAvailablePhotos{
                    self.thePin.numberOfAvailablePhotos = numberOfAvailablePhotos
                }
                
                // Save the urls into the photos array associated with the pin
                for url in arrayOfURLs {
                    
                    // Extract the last component of the url to be the file name on disc
                    let fileNameOnDisc = NSURL(string: url)?.lastPathComponent
                    
                    let dictionary: [String : AnyObject] = [
                        Photo.Keys.PhotoPath: url,
                        Photo.Keys.PhotoNameOnDisc: fileNameOnDisc!
                    ]
                    let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                    photo.pin = self.thePin
                }
                CoreDataStackManager.sharedInstance().saveContext()
                
                dispatch_async(dispatch_get_main_queue()) {
                    // Enable the bottom button
                    self.bottomButton.enabled = true
                    
                    // Display the noPinsLabel if this pin has no photos available
                    if numberOfAvailablePhotos == 0 {
                        self.noPinsLabel.hidden = false
                    }
                }
                
            } else {
                // Display an alert with the error for the user
                self.displayError(errorString)
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
    
    
    // MARK: - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        self.configureCell(cell, photo: photo)
        
        // Darken the cell a little to highlight its selected state.
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.photoImageView!.alpha = 0.25
        } else {
            cell.photoImageView!.alpha = 1.0
        }
        
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Reload the selected cell to reflect the action of selecting it
        UIView.performWithoutAnimation({
            collectionView.reloadItemsAtIndexPaths([indexPath])
        })
        
        // And update the buttom button
        updateBottomButton()
    }
    
    // MARK: - Configure Cell
    
    func configureCell(cell: PhotoCell, photo: Photo) {
        
        var imageForPhoto = UIImage(named: "photoPlaceholder")
        
        cell.photoImageView!.image = nil
        cell.associatedURL = photo.photoPath!
        
        if photo.photoImage != nil {
            imageForPhoto = photo.photoImage
            cell.activityIndicator.stopAnimating()
        } else {
            
            cell.photoImageView!.image = imageForPhoto
            cell.activityIndicator.startAnimating()
            
            // Start the task that will eventually download the image
            let task = FlikrClient.sharedInstance().taskForImage(photo.photoPath!) { imageData, error in
                
                if let _ = error {
                    //print("Image download error: \(error.localizedDescription)")
                }
                
                if let data = imageData {
                    // Create the image
                    let image = UIImage(data: data)
                    
                    // Check if this is the same image used for this specific cell!
                    if cell.associatedURL == photo.photoPath!{
                        // Update the model, so that the information gets cashed
                        photo.photoImage = image
                        
                        // Update the cell later, on the main thread
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.activityIndicator.stopAnimating()
                            cell.photoImageView!.image = image
                        }
                    }
                    
                }
            }
            
            // This should cancel the task if the cell is reused
            cell.taskToCancelifCellIsReused = task
        }
        
        cell.photoImageView!.image = imageForPhoto
    }
    
    
    // MARK: - Core Data Convenience.
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.thePin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    
    // MARK: - Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the index paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            /* Here we are noting that a new Photo instance has been added to Core Data. We remember its index path so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has the index path that we want in this case. */
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            /* Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has value that we want in this case. */
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            // Use this to update the photos when downloaded.
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            // Do nothing
            break
        default:
            break
        }
    }
    
    /* This method is invoked after all of the changed in the current batch have been collected into the three index path arrays (insert, delete, and upate). We now need to loop through the arrays and perform the changes. */
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    
    
    // MARK: - Helper functions
    
    @IBAction func clickTheBottomButton(sender: UIButton) {
        
        if selectedIndexes.isEmpty {
            reloadOtherPhotos()
        } else {
            deleteSelectedPhotos()
        }
        
        updateBottomButton()
        
    }
    
    
    func reloadOtherPhotos() {
        
        // First check for the availability of an internet connection
        if reachabilityStatus == kNOTREACHABLE {
            displayMessage("The Internet connection appears to be offline.")
        } else if thePin.numberOfAvailablePhotos >= 0 && thePin.numberOfAvailablePhotos <= 21 { // The app tries to download the available photos associated with this pin in the past and only a set of < 21 photos were available; There's no more photos to download
            // Display a message that there are no other photos to download for this pin
            displayMessage("This pin has no other images.")
        } else {
            
            // Delete all the photos
            for photo in fetchedResultsController.fetchedObjects as! [Photo] {
                sharedContext.deleteObject(photo)
            }
            
            // Download another set of photos
            downloadThePhotos()

        }
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        selectedIndexes = [NSIndexPath]()
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.setTitle("Remove Selected Photos", forState: UIControlState.Normal)
        } else {
            bottomButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
    }
    
    func displayMessage(messageString: String) {
        // Prepare the Alert view controller with the error message to display
        let alert = UIAlertController(title: "", message: messageString, preferredStyle: .Alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(dismissAction)
        dispatch_async(dispatch_get_main_queue(), {
            // Display the Alert view controller
            self.presentViewController (alert, animated: true, completion: nil)
        })
    }

}