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
  
  // MARK: Properties
  private var currentViewController: UIViewController
  
  // MARK: Initializers
  init() {
    self.currentViewController = SplashViewController()
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // for testing auth (not for production)
    UserDefaults.standard.set(false, forKey: "LOGGED_IN")
    self.setNeedsStatusBarAppearanceUpdate()
    
    addChildViewController(currentViewController)
    currentViewController.view.frame = view.bounds
    view.addSubview(currentViewController.view)
    currentViewController.didMove(toParentViewController: self)
  }
}

// MARK: - Navigations
extension AppRootViewController {
  
  func toLoginScreen() {
    // let newViewController = UINavigationController(rootViewController: AuthViewController())
    
    guard let newViewController = AuthViewController.storyboardInitialInstance() else {
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
    
    guard let newViewController = MainViewController.storyboardInitialInstance() else {
      assertionFailure("No UIStoryboard with name: Main")
      return
    }
    
    // let mainViewController = MainViewController()
    // let newViewController = UINavigationController(rootViewController: mainViewController)
    animateFadeTransition(to: newViewController)
  }
  
  func toLogoutScreen() {
    guard let newViewController = AuthViewController.storyboardInitialInstance() else {
      assertionFailure("No UIStoryboard with name: Auth")
      return
    }
    
    // let authViewController = AuthViewController()
    // let newViewController = UINavigationController(rootViewController: authViewController)
    animateDismissTransition(to: newViewController)
  }
  
}

// MARK: - Navigation Animations
extension AppRootViewController {
  
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
