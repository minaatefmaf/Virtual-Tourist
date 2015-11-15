//
//  TaskCancelingCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Mina Atef on 11/15/15.
//  Copyright © 2015 minaatefmaf. All rights reserved.
//

import Foundation

import UIKit

class TaskCancelingCollectionViewCell: UICollectionViewCell {

    // The property uses a property observer. Any time its value is set it canceles the previous NSURLSessionTask.
    
    var imageName: String = ""

    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
