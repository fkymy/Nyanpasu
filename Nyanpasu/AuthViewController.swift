//
//  AuthViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import Firebase

extension AuthViewController: StoryboardInitialInstance {
  static var storyboardName: String { return "Auth" }
}

class AuthViewController: UIViewController {
  
  // MARK: Properties
  private var handle: AuthStateDidChangeListenerHandle?
  private let bottomSpacing: CGFloat = 64
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  // MARK: IBOutlets
  @IBOutlet weak var usernameField: UITextField!
  @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
  
  // MARK: UIViewController Lifecycle
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.setNeedsStatusBarAppearanceUpdate()
    
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
    handle = Auth.auth().addStateDidChangeListener { (auth, user) in
      // ...
      
      if let user = user {
        // the user's ID, unique to the firebase project.
        // DO NOT use this value to authenticate with your backend server
        // if you have one. Use getTokenWithCompletion:completion: instead.
        let name = user.displayName ?? "no displayName"
        print("[Auth] addStateDidChangeListener for user \(user.uid)] \(name)")

        // navigate to Main
        // AppDelegate.shared.rootViewController.toMainScreen()
      }
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillAppear(animated)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
    Auth.auth().removeStateDidChangeListener(handle!)
  }

  @objc func handleKeyboardWillShow(_ notification: Notification) {
    if let keyboardFrameEndUserInfo = ((notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
      let keyboardEndFrame = keyboardFrameEndUserInfo.cgRectValue
      let convertedKeyboardEndFrame = view.convert(keyboardEndFrame, from: view.window)
      bottomLayoutGuideConstraint.constant = view.bounds.maxY - convertedKeyboardEndFrame.minY
    }
  }
  
  @objc func handleKeyboardWillHide(_ notification: Notification) {
    bottomLayoutGuideConstraint.constant = bottomSpacing
  }
}

// MARK: - IBActions
extension AuthViewController {
  
  @IBAction func login(_ sender: UIButton) {
    // validate
    guard let username = usernameField.text, username != "" else {
      let alert = UIAlertController(title: "", message: "Enter Username", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel))
      present(alert, animated: true)
      return
    }
    
    Auth.auth().signInAnonymously { (authResult, error) in
      if let error = error {
        print(error.localizedDescription)
        return
      }

      if let user = authResult?.user {
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = username
        changeRequest.commitChanges { (error) in
          if let error = error {
            print(error.localizedDescription)
            return
          }
        }

        // store the user session (example only, not for the production)
        UserDefaults.standard.set(true, forKey: "LOGGED_IN")
        AppDelegate.shared.rootViewController.toMainScreen()
      }
      else {
        print("authResult?.user is nil")
        return
      }
    }
  }
}
