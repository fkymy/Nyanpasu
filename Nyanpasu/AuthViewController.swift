//
//  AuthViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import Firebase

extension AuthViewController: StoryboardInstance {
  static var storyboardName: String {
    return "Auth"
  }
}

class AuthViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
  }
  
  @IBAction func login(_ sender: UIButton) {
    // store the user session (example only, not for the production)
    UserDefaults.standard.set(true, forKey: "LOGGED_IN")
    
    // navigate to Main
    AppDelegate.shared.rootViewController.toMainScreen()
  }
}
