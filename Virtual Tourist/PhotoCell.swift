//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/15/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import UIKit

class PhotoCell: TaskCancelingCollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // Use this as a temporary url for checking if the image is the right one for the associated cell (when downloading the image in the collection view using a reused cell)
    var associatedURL = ""
}