//
//  StoryboardInstance.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

protocol StoryboardInstance {
  static var storyboardName: String { get }
  static var bundle: Bundle? { get }
}

extension StoryboardInstance where Self: UIViewController {
  static var bundle: Bundle? {
    return nil
  }
  
  static func storyboardInstance() -> UIViewController? {
    let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
    return storyboard.instantiateInitialViewController()
  }
}

extension StoryboardInstance where Self: UIView {
  
}
