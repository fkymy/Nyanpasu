//
//  MainViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import Firebase
import Speech

extension MainViewController: StoryboardInitialInstance {
  static var storyboardName: String { return "Main" }
}

class MainViewController: UIViewController {
  
  // MARK: Properties
  var user: User!
  private var userHandle: AuthStateDidChangeListenerHandle?
  private let rooms: [Room] = Room.all()
  var miniPlayer: MiniPlayerViewController?

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: IBOutlets
  @IBOutlet weak var collectionView: UICollectionView!

  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setNeedsStatusBarAppearanceUpdate()
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(RoomCell.self, forCellWithReuseIdentifier: RoomCell.identifier)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    userHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
      if let user = user {
        self.user = User(uid: user.uid, displayName: user.displayName, photoURL: user.photoURL)
      }
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    authorizeSpeech()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    Auth.auth().removeStateDidChangeListener(userHandle!)
  }
  
  deinit {
    Auth.auth().removeStateDidChangeListener(userHandle!)
  }
}

// MARK - User View
extension MainViewController {
  @objc func enterRoom(sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      let controller = RoomViewController.fromStoryboard()
      controller.user = user
      self.navigationController?.pushViewController(controller, animated: true)
    }
  }
}

// MARK - IBActions
extension MainViewController {
  @IBAction func logout(_ sender: UIButton) {
    // handle logout...
    // clear user session (example only, not for production)
    UserDefaults.standard.set(false, forKey: "LOGGED_IN")
    
    // navigate to Auth
    AppDelegate.shared.rootViewController.toLogoutScreen()
  }
}

// MARK - UICollectionViewDataSource
extension MainViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return rooms.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RoomCell.identifier, for: indexPath) as! RoomCell
    cell.room = rooms[indexPath.item]
    return cell
  }
}

// MARK: - UICollectionViewDelegate
extension MainViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    miniPlayer?.configure(room: rooms[indexPath.item])
    
    let controller = RoomViewController.fromStoryboard()
    controller.user = user
    self.navigationController?.pushViewController(controller, animated: true)
  }
}

// MARK: - Speech
extension MainViewController {
  func authorizeSpeech() {
    SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
      switch authStatus {
      case .authorized:
        print("Speech Recognition Authorized")
      case .denied:
        print("Speech Recognition Denied")
      case .restricted:
        print("Speech Recognition not available")
      case .notDetermined:
        print("Not Determined")
      }
    }
  }
}

extension UIColor {
  static var appBackgroundColor: UIColor {
    return UIColor(red:0.07, green:0.09, blue:0.11, alpha:1.0)
  }
  
  static var secondaryBackgroundColor: UIColor {
    return UIColor(red:0.13, green:0.15, blue:0.17, alpha:1.0)
  }
}

