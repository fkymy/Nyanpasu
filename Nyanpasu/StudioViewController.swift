//
//  StudioViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/04.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

class StudioViewController: UIViewController {
  
  // MARK: Properties
  var user: User! {
    didSet {
      if let user = user {
        print("[user] \(user.uid) \(user.displayName!) entered studio")
        title = user.displayName
      }
    }
  }
  
  // MARK: IBOutlets
  
  var messages: [Message]?

  override func viewDidLoad() {
    super.viewDidLoad()
  }
}

extension StudioViewController: UICollectionViewDelegate {
  
}
