//
//  AppRootViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

extension AppDelegate {
  static var shared: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
  }
  
  var rootViewController: AppRootViewController {
    return window!.rootViewController as! AppRootViewController
  }
}

class AppRootViewController: UIViewController {
  
  private var currentViewController: UIViewController
  
  init() {
    self.currentViewController = SplashViewController()
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addChildViewController(currentViewController)
    currentViewController.view.frame = view.bounds
    view.addSubview(currentViewController.view)
    currentViewController.didMove(toParentViewController: self)
  }
}

// MARK: - Navigation
extension AppRootViewController {
  
  func toLoginScreen() {
    // let newViewController = UINavigationController(rootViewController: AuthViewController())
    
    guard let newViewController = AuthViewController.storyboardInstance() else {
      assertionFailure("No UIStoryboard with name: Auth")
      return
    }
    
    addChildViewController(newViewController)
    newViewController.view.frame = view.bounds
    view.addSubview(newViewController.view)
    newViewController.didMove(toParentViewController: self)
    
    currentViewController.willMove(toParentViewController: nil)
    currentViewController.view.removeFromSuperview()
    currentViewController.removeFromParentViewController()
    
    currentViewController = newViewController
  }
  
  func toMainScreen() {
    
    guard let newViewController = MainViewController.storyboardInstance() else {
      assertionFailure("No UIStoryboard with name: Main")
      return
    }
    
    // let mainViewController = MainViewController()
    // let newViewController = UINavigationController(rootViewController: mainViewController)
    animateFadeTransition(to: newViewController)
  }
  
  func toLogoutScreen() {
    guard let newViewController = AuthViewController.storyboardInstance() else {
      assertionFailure("No UIStoryboard with name: Auth")
      return
    }
    
    // let authViewController = AuthViewController()
    // let newViewController = UINavigationController(rootViewController: authViewController)
    animateDismissTransition(to: newViewController)
  }
  
  private func animateFadeTransition(to newViewController: UIViewController, completion: (() -> Void)? = nil) {
    currentViewController.willMove(toParentViewController: nil)
    addChildViewController(newViewController)
    
    transition(from: currentViewController, to: newViewController, duration: 0.2, options: [.transitionCrossDissolve, .curveEaseOut], animations: {
      
    }) { (completed) in
      self.currentViewController.removeFromParentViewController()
      newViewController.didMove(toParentViewController: self)
      self.currentViewController = newViewController
      completion?()
    }
  }
  
  private func animateDismissTransition(to newViewController: UIViewController, completion: (() -> Void)? = nil) {
    let initialFrame = CGRect(x: -view.bounds.width, y: 0, width: view.bounds.width, height: view.bounds.height)
    currentViewController.willMove(toParentViewController: nil)
    addChildViewController(newViewController)
    newViewController.view.frame = initialFrame
    
    transition(from: currentViewController, to: newViewController, duration: 0.2, options: [], animations: {
      newViewController.view.frame = self.view.bounds
    }) { (completed) in
      self.currentViewController.removeFromParentViewController()
      newViewController.didMove(toParentViewController: self)
      self.currentViewController = newViewController
      completion?()
    }
  }
}
