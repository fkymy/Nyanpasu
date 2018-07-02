//
//  SplashViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

class SplashViewController: UIViewController {
  
  private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.red
    view.addSubview(activityIndicator)
    activityIndicator.frame = view.bounds
    activityIndicator.backgroundColor = UIColor(white: 0, alpha: 0.4)
    
    makeServiceCall()
  }
  
  private func makeServiceCall() {
    activityIndicator.startAnimating()
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(3)) {
      self.activityIndicator.stopAnimating()
      
      if UserDefaults.standard.bool(forKey: "LOGGED_IN") {
        // navigate to Main
        AppDelegate.shared.rootViewController.toMainScreen()
      }
      else {
        // navigate to Auth
        AppDelegate.shared.rootViewController.toLoginScreen()
      }
    }
  }
}
