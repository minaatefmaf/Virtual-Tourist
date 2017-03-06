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
    var selectedIndexes = [IndexPath]()
    
    // Keep the changes; keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        /* If numberOfAvailablePhotos is -ve: no previous attempt was made to download this pin's photos.
           If numberOfAvailablePhotos == 0: found no photos associated with this pin if the first attempt (with a successful internet connection) was made*/
        if thePin.numberOfAvailablePhotos < 0 {
            downloadThePhotos()
        } else if thePin.numberOfAvailablePhotos == 0 {
            noPinsLabel.isHidden = false
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
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        
        // Hide the noPinsLabel
        noPinsLabel.isHidden = true
    }
    
    func downloadThePhotos() {
        
        // Disable the bottom button
        self.bottomButton.isEnabled = false
        
        // Initiate the dowloading process
        FlikrClient.sharedInstance.getThePhotosFromFlikr(thePin.latitude, longitude: thePin.longitude) { success, numberOfAvailablePhotos, arrayOfURLs, errorString in
            
            if success {
                
                // Save the numberOfAvailablePhotos to the Pin
                if let numberOfAvailablePhotos = numberOfAvailablePhotos{
                    self.thePin.numberOfAvailablePhotos = numberOfAvailablePhotos
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
                    photo.pin = self.thePin
                }
                CoreDataStackManager.sharedInstance.saveContext()
                
                DispatchQueue.main.async {
                    // Enable the bottom button
                    self.bottomButton.isEnabled = true
                    
                    // Display the noPinsLabel if this pin has no photos available
                    if numberOfAvailablePhotos == 0 {
                        self.noPinsLabel.isHidden = false
                    }
                }
                
            } else {
                // Display an alert with the error for the user
                self.displayError(errorString)
            }
            
        }
    }
    
    func displayError(_ errorString: String?) {
        if let errorString = errorString {
            // Prepare the Alert view controller with the error message to display
            let alert = UIAlertController(title: "", message: errorString, preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default, handler: nil)
            alert.addAction(dismissAction)
            DispatchQueue.main.async(execute: {
                // Display the Alert view controller
                self.present (alert, animated: true, completion: nil)
            })
        }
    }
    
    
    // MARK: - UICollectionView
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let photo = fetchedResultsController.object(at: indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        self.configureCell(cell, photo: photo)
        
        // Darken the cell a little to highlight its selected state.
        if let _ = selectedIndexes.index(of: indexPath) {
            cell.photoImageView!.alpha = 0.25
        } else {
            cell.photoImageView!.alpha = 1.0
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.index(of: indexPath) {
            selectedIndexes.remove(at: index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Reload the selected cell to reflect the action of selecting it
        UIView.performWithoutAnimation({
            collectionView.reloadItems(at: [indexPath])
        })
        
        // And update the buttom button
        updateBottomButton()
    }
    
    // MARK: - Configure Cell
    
    func configureCell(_ cell: PhotoCell, photo: Photo) {
        
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
            let task = FlikrClient.sharedInstance.taskForImage(photo.photoPath!) { imageData, error in
                
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
                        DispatchQueue.main.async {
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
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }()
    
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = { () -> <<error type>> in 
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
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
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the index paths into the three arrays.
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type{
            
        case .insert:
            /* Here we are noting that a new Photo instance has been added to Core Data. We remember its index path so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has the index path that we want in this case. */
            insertedIndexPaths.append(newIndexPath!)
            break
        case .delete:
            /* Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has value that we want in this case. */
            deletedIndexPaths.append(indexPath!)
            break
        case .update:
            // Use this to update the photos when downloaded.
            updatedIndexPaths.append(indexPath!)
            break
        case .move:
            // Do nothing
            break
        }
    }
    
    /* This method is invoked after all of the changed in the current batch have been collected into the three index path arrays (insert, delete, and upate). We now need to loop through the arrays and perform the changes. */
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }
            
            }, completion: nil)
    }
    
    
    
    // MARK: - Helper functions
    
    @IBAction func clickTheBottomButton(_ sender: UIButton) {
        
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
                sharedContext.delete(photo)
            }
            
            // Download another set of photos
            downloadThePhotos()

        }
    }
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.object(at: indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.delete(photo)
        }
        
        CoreDataStackManager.sharedInstance.saveContext()
        
        selectedIndexes = [IndexPath]()
    }
    
    func updateBottomButton() {
        if selectedIndexes.count > 0 {
            bottomButton.setTitle("Remove Selected Photos", for: UIControlState())
        } else {
            bottomButton.setTitle("New Collection", for: UIControlState())
        }
    }
    
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

}
