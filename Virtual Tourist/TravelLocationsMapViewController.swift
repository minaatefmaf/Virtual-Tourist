//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/11/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomView: UIView!
    
    // Add long press recognizer
    var longPressRecognizer: UILongPressGestureRecognizer? = nil
    // Edit mode: when deleting the pins happen
    var editMode = false
    // To know if the user is still on the same press
    var longPressIsActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the right bar button
        let editButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editPins")
        self.navigationItem.setRightBarButtonItems([editButton], animated: true)
        
        /* Configure tap recognizer */
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: "handleSingleLongPress:")
        longPressRecognizer?.minimumPressDuration = 0.5
        
        // Set the delegate to this view controller
        self.mapView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        addAnotationRecognizer()
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
        // Switch back to the original mode
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
        // Navigate to the Photo Album View
        let photoAlbumController = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        self.navigationController!.pushViewController(photoAlbumController, animated: true)
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
            // TODO: Remove selected pins
        } else if !longPressIsActive {
            let tapPostion = recognizer.locationInView(mapView)
            let coordinate = self.mapView.convertPoint(tapPostion, toCoordinateFromView: self.mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            //var annotations = [MKPointAnnotation]()
            //annotations.append(annotation)
            
            self.mapView.addAnnotation(annotation)
            
            
            // Set longPressIsActive to true so only one annotation is added
            longPressIsActive = true
        }
        
        // Set longPressIsActive to false after the continuous gesture touch is ended
        if (recognizer.state == .Ended) {
            longPressIsActive = false
        }
        
    }

}

