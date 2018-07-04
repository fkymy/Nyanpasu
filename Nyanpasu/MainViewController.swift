//
//  MainViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/02.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import Firebase

extension MainViewController: StoryboardInitialInstance {
  static var storyboardName: String { return "Main" }
}

class MainViewController: UIViewController {
  
  // MARK: Properties
  var user: User! {
    didSet {
      userDisplayNameLabel.text = user.displayName ?? "Anonymous"
      userLatestMessage.text = "今日はどんな感じ？ やっぱキャンプいい..."
    }
  }
  private var userHandle: AuthStateDidChangeListenerHandle?
  
  private let rooms: [Room] = Room.all()
  
  private var studio: StudioViewController?
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  // MARK: IBOutlets
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var userView: UIView!
  @IBOutlet weak var userProfileImage: UIImageView!
  @IBOutlet weak var userDisplayNameLabel: UILabel!
  @IBOutlet weak var userLatestMessage: UILabel!
  
  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(RoomCell.self, forCellWithReuseIdentifier: RoomCell.identifier)
    
    userView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(enterStudio(sender:))))
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.setNeedsStatusBarAppearanceUpdate()
    userHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
      if let user = user {
        self.user = User(uid: user.uid, displayName: user.displayName, photoURL: user.photoURL)
      }
    }
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
  @objc func enterStudio(sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      let controller = StudioViewController.fromStoryboard()
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
    print("room \(indexPath.item) was tapped")
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
