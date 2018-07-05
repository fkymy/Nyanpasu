//
//  RoomsFlowLayout.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/04.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

class RoomsFlowLayout: UICollectionViewFlowLayout {

  // called whenever the layout is invalidated
  // in flowlayout, its when view's bounds and size changes (rotation, resize)
  // great place to do customization that takes size of view in account
  override func prepare() {
    super.prepare()
    
    guard let cv = collectionView else { return }
    
    // cv.bounds.inset(by: cv.layoutMargins).size.width
    
    // Default
    // self.itemSize = CGSize(width: cv.bounds.insetBy(dx: cv.layoutMargins.left, dy: cv.layoutMargins.top).size.width, height: 70.0)
    
    // Have 2 or more columns in rW
    let availableWidth = cv.bounds.insetBy(dx: cv.layoutMargins.left, dy: cv.layoutMargins.top).size.width
    let minColumnWidth = CGFloat(300.0)
    let maxNumColumns = Int(availableWidth / minColumnWidth)
    let cellWidth = (availableWidth / CGFloat(maxNumColumns)).rounded(.down)
    self.itemSize = CGSize(width: cellWidth, height: 80.0)
    
    self.sectionInset = UIEdgeInsets(top: self.minimumInteritemSpacing, left: 0.0, bottom: 0.0, right: 0.0)
    self.sectionInsetReference = .fromSafeArea
  }
}
