//
//  ViewController.swift
//  Scroll
//
//  Created by Rick Lewis on 12/14/16.
//  Copyright © 2016 Rick Lewis Industries. All rights reserved.
//

import UIKit

let IMAGESPERWORD: Int = 40

let WORDIMAGESCALINGFACTOR: Double = 0.75

let SCROLLROWHEIGHT: Int = 100

let LOADINGROWHEIGHT: Int = 48

let MAXNUMROWS: Int = 6

let NUMPROFILES: Int = 200

let ARC4RANDOM_MAX: Float = 0x100000000

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var textModel: [[Int]] = [] // String of ints corresponding to word lengths for each cell
    
    var profileModel: [Int] = [] // Integer indices of profile to use for each cell
    
    var images: [UIImage] = [] // Array of preassembled animated words, indexed by length (space is at index 0)
    
    var tableViewCellModel: NSCache<NSNumber, ScrollTableViewCell> = NSCache<NSNumber, ScrollTableViewCell>() // Cache of premade scroll cells
    
    var collectionViewCellModel: NSCache<NSNumber, NSCache<NSNumber, UICollectionViewCell>> = NSCache<NSNumber, NSCache<NSNumber, UICollectionViewCell>>() // Cache of premade word cells
    
    var cellWidths: [CGSize]  = [] // Cached cell sizes
    
    var numScrolls: Int = 0 // Number of scrolls in existence (may not all have been created yet)
    
    var isLoading: Bool = false // Tracks whether new cells are currently being generated
    
    
    // MARK: - Overridden UIViewController methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for wordLength in 0...12 {
            images.append(generateWordImage(wordLength))
            cellWidths.append(CGSize(width: (wordLength > 0 ?
                (Double(wordLength) * 8 * WORDIMAGESCALINGFACTOR) : (8 * WORDIMAGESCALINGFACTOR)), height: 8 * WORDIMAGESCALINGFACTOR))
        }
        tableViewCellModel.countLimit = 400 // Maximum number of scrolls to hold in cache - when this is exceeded, the oldest scrolls will be deleted and must be regenerated
        collectionViewCellModel.countLimit = 8000
        generateScrollCells(40, startIndex: 0)
    }
    
    // MARK: - Public memory management methods
    
    // Empties NSCache containing cells - called when app enters background
    func clearCaches() {
        tableViewCellModel.removeAllObjects()
        collectionViewCellModel.removeAllObjects()
    }
    
    // Reloads all currently existing cells into NSCache - called when app reenters foreground
    func fillCellCache() {
        let numNewScrolls = numScrolls
        numScrolls = 0
        generateScrollCells(numNewScrolls, startIndex: 0)
    }
    
    // MARK: - Convenience methods
    
    
    // Returns random floating point number between 0 (inclusive) and 1 (excluded)
    func getRandom() -> Float {
        return Float(arc4random()) / ARC4RANDOM_MAX
    }
    
    // Generates word pattern of scroll as integer array
    func generateScrollTextPattern(_ frameWidth: Int) -> [Int] {
        var textPattern: [Int] = []
        let totalNumWords = Int(getRandom() * 25) + 10
        var numRows = 0
        var lineWidth = 0
        for _ in 1...totalNumWords {
            let nextWordLength = Int(getRandom() * 10) + 1
            if (lineWidth + (nextWordLength * Int(8.0 * WORDIMAGESCALINGFACTOR)) <= frameWidth) {
                textPattern.append(nextWordLength)
                lineWidth += nextWordLength * Int(8.0 * WORDIMAGESCALINGFACTOR)
                if (lineWidth + Int(8.0 * WORDIMAGESCALINGFACTOR) <= frameWidth) {
                    textPattern.append(0)
                    lineWidth += Int(8.0 * WORDIMAGESCALINGFACTOR)
                }
            } else {
                numRows += 1
                if (numRows >= MAXNUMROWS) {
                    break
                }
                while (lineWidth + Int(8.0 * WORDIMAGESCALINGFACTOR) <= frameWidth) {
                    textPattern.append(0)
                    lineWidth += Int(8.0 * WORDIMAGESCALINGFACTOR)
                }
                textPattern.append(nextWordLength)
                textPattern.append(0)
                lineWidth = (nextWordLength + 1) * Int(8.0 * WORDIMAGESCALINGFACTOR)
            }
        }
        while (lineWidth + Int(8.0 * WORDIMAGESCALINGFACTOR) <= frameWidth) {
            textPattern.append(0)
            lineWidth += Int(8.0 * WORDIMAGESCALINGFACTOR)
        }
        return textPattern
    }
    
    // Generates word image of requested width
    func generateWordImage (_ width: Int) -> UIImage {
        if (width > 0) {
            var animatedImages: [UIImage] = []
            for index in 0...IMAGESPERWORD - 1 {
                animatedImages.append(UIImage(named: "width\(width)-\(index).png")!)
            }
            return UIImage.animatedImage(with: animatedImages, duration: 4.0)!
         } else {
        return #imageLiteral(resourceName: "space")
        }
    }
    
    // Generates a given number of new cells, indexed sequentially starting at the given index - this asynchronous loading helps speed up new cell requests from the TableView
    func generateScrollCells(_ numCells: Int, startIndex start: Int) {
        let tableView = view.subviews[0] as! UITableView
        numScrolls += numCells
        for i in 0...numCells - 1 {
            let scrollViewCell = tableView.dequeueReusableCell(withIdentifier: "scroll") as! ScrollTableViewCell
            tableViewCellModel.setObject(scrollViewCell, forKey: NSNumber(integerLiteral: start + i))
            textModel.append(generateScrollTextPattern(scrollViewCell.getCollectionViewWidth()))
            profileModel.append(Int(getRandom() * Float(NUMPROFILES)) + 1)
            scrollViewCell.setCollectionViewTag(start + i)
        }
    }
    
    // Inserts "loading" cell, preps new row addition
    func loadNewRows(_ tableView: UITableView) {
        isLoading = true
        numScrolls += 1
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: numScrolls - 1, section: 0)], with: UITableViewRowAnimation.none)
        tableView.endUpdates()
        generateScrollCells(40, startIndex: numScrolls - 1)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: { self.addNewRows(tableView) })
    }
    
    // Removes "loading" cell, adds new rows
    func addNewRows(_ tableView: UITableView) {
        if (isLoading) {
            isLoading = false
            numScrolls -= 1
            tableView.beginUpdates()
            tableView.deleteRows(at: [IndexPath(row: numScrolls - 40, section: 0)], with: UITableViewRowAnimation.none)
            var indexPaths: [IndexPath] = []
            for rowNum in numScrolls - 40...numScrolls - 1 {
                indexPaths.append(IndexPath(row: rowNum, section: 0))
            }
            tableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.none)
            tableView.endUpdates()
        }
    }
    
    
    // MARK: - Required UITableViewDataSource methods
    
    
    // Creates new scroll cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (isLoading && indexPath.row == numScrolls - 1) {
            return tableView.dequeueReusableCell(withIdentifier: "loading")!
        } else {
            if let scrollViewCell = tableViewCellModel.object(forKey: NSNumber(value: indexPath.row)) {
                return scrollViewCell
            } else {
                let scrollViewCell = tableView.dequeueReusableCell(withIdentifier: "scroll") as! ScrollTableViewCell
                tableViewCellModel.setObject(scrollViewCell, forKey: NSNumber(value: indexPath.row))
                return scrollViewCell
            }
        }
    }
    
    // Provides number of sections in table (only 1, labeled "scroll")
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    // Provides number of scrolls currently in existence
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return numScrolls
    }
    
    // Returns header text for section (always just "scroll")
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "scroll"
    }
    
    
    // MARK: - Required UITableViewDelegate Methods
    
    
    // Called when user stops scrolling table view - used to determine when to load new scrolls
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset
        let y = offset.y + bounds.size.height - inset.bottom
        let h = size.height
        let reloadDistance = 5
        if (y > h + CGFloat(reloadDistance) && !isLoading) {
            loadNewRows(scrollView as! UITableView)
        }
    }
    
    // Called just before scroll is displayed, used to set collection view's parent and profile image
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let scrollViewCell = cell as? ScrollTableViewCell {
            scrollViewCell.assignProfile(self.profileModel[indexPath.row])
        }
    }
    
    // Provides height for each row (varies for scroll vs loading)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (isLoading && indexPath.row == numScrolls - 1) {
            return CGFloat(LOADINGROWHEIGHT)
        } else {
            return CGFloat(SCROLLROWHEIGHT)
        }
    }
    
    // Provides custom section header appearance, as a custom UIView
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 32.5))
        header.backgroundColor = UIColor.white
        header.text = "scroll"
        header.textColor = UIColor.darkGray
        header.font = UIFont(name: "Quicksand-Bold", size: 20)
        header.textAlignment = NSTextAlignment.center
        header.isOpaque = true
        let border = UIView(frame: CGRect(x: 8, y: 32.25, width: tableView.frame.size.width - 16, height: 0.25))
        border.backgroundColor = UIColor.lightGray
        border.isOpaque = true
        header.addSubview(border)
        return header
    }
    
    // Provides custom section header height
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32.5
    }
    
    
    // MARK: - Required UICollectionViewDataSource methods
    
    
    // Creates new collection view cell
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let scrollCellCache = collectionViewCellModel.object(forKey: NSNumber(value: collectionView.tag)) {
            if let wordCell = scrollCellCache.object(forKey: NSNumber(value: indexPath.row)) {
                return wordCell
            } else {
                let wordCell = collectionView.dequeueReusableCell(withReuseIdentifier: "wordCell", for: indexPath)
                // The following two lines decrease scrolling lag by rasterizing (storing as a local bitmap prior to display) the collection view cell images
                wordCell.layer.shouldRasterize = true
                wordCell.layer.rasterizationScale = UIScreen.main.scale
                let wordCellImageView = UIImageView(image: images[textModel[collectionView.tag][indexPath.row]])
                wordCell.contentView.addSubview(wordCellImageView)
                scrollCellCache.setObject(wordCell, forKey: NSNumber(value: indexPath.row))
                return wordCell
            }
        } else {
            let scrollCellCache = NSCache<NSNumber, UICollectionViewCell>()
            let wordCell = collectionView.dequeueReusableCell(withReuseIdentifier: "wordCell", for: indexPath)
            // The following two lines decrease scrolling lag by rasterizing (storing as a local bitmap prior to display) the collection view cell images
            wordCell.layer.shouldRasterize = true
            wordCell.layer.rasterizationScale = UIScreen.main.scale
            let wordCellImageView = UIImageView(image: images[textModel[collectionView.tag][indexPath.row]])
            wordCell.contentView.addSubview(wordCellImageView)
            scrollCellCache.setObject(wordCell, forKey: NSNumber(value: indexPath.row))
            collectionViewCellModel.setObject(scrollCellCache, forKey: NSNumber(value: collectionView.tag))
            return wordCell
        }
    }
    
    // Provides number of words and spaces in given scroll
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if (collectionView.tag >= 0 && collectionView.tag < textModel.count) {
            return textModel[collectionView.tag].count
        } else {
            return 0
        }
    }
    
    
    // MARK: - UICollectionViewDelegateFlowLayout methods
    
    
    // Informs flow layout of each cell's size in each collection view
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellWidths[textModel[collectionView.tag][indexPath.row]]
    }
    
    // Informs flow layout of spacing to insert between successive rows in collection view
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(8 * WORDIMAGESCALINGFACTOR)
    }
}

