//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/12/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import UIKit
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
}