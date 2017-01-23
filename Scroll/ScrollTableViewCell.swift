//
//  ScrollTableViewCell.swift
//  Scroll
//
//  Created by Rick Lewis on 12/18/16.
//  Copyright © 2016 Rick Lewis Industries. All rights reserved.
//

import UIKit

let NONCONTENTSPACE = 95

class ScrollTableViewCell: UITableViewCell {
    
    @IBOutlet var imgProfile: UIImageView?
    
    @IBOutlet private var scrollCollectionView: UICollectionView? // Private so as not to violate MVC (the view controller shouldn't access the collection view through the cell view)
        
    override func awakeFromNib() {
        super.awakeFromNib()
        scrollCollectionView!.tag = -1
    }
    
    // Used to assign image using model in viewControler
    func assignProfile(_ profileIndex: Int) {
        if let img = imgProfile as UIImageView! {
            img.image = UIImage(named: "profile\(profileIndex).png")
        }
    }
    
    // Returns width of UICollectionView subview of cell, which is device-dependent
    func getCollectionViewWidth() -> Int {
        return Int(UIScreen.main.bounds.size.width) - NONCONTENTSPACE
    }
    
    // Sets index value for enclosed collection view and reloads its data if necessary
    func setCollectionViewTag(_ tag: Int) {
        if (scrollCollectionView!.tag != tag) {
            scrollCollectionView!.tag = tag
            scrollCollectionView!.reloadData()
        }
    }
}
