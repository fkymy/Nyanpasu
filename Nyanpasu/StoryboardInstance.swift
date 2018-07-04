//
//  StoryboardInstance.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

protocol StoryboardInitialInstance {
  static var storyboardName: String { get }
  static var bundle: Bundle? { get }
}

extension StoryboardInitialInstance where Self: UIViewController {
  static var bundle: Bundle? {
    return nil
  }
  
  static func storyboardInitialInstance() -> UIViewController? {
    let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
    return storyboard.instantiateInitialViewController()
  }
}

protocol StoryboardInstance {
  static var storyboardName: String { get }
  static var storyboardID: String { get }
  static var bundle: Bundle? { get }
}

extension StoryboardInstance where Self: UIViewController {
  static var storyboardID: String {
    return String(describing: self)
  }
  
  static var bundle: Bundle? {
    return nil
  }
  
  static func fromStoryboard() -> Self {
    let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
    let controller = storyboard.instantiateViewController(withIdentifier: storyboardID) as! Self
    return controller
  }
}
