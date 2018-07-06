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
  
  // MARK: Basic Properties
  private var rooms: [Room] = []
  var user: User! {
    didSet {
      if let user = user {
        print("[user] \(user.uid) \(user.displayName!) entered room")
      }
    }
  }
  private var userHandle: AuthStateDidChangeListenerHandle?
  private var documents: [DocumentSnapshot] = []
  private var listener: ListenerRegistration?
  fileprivate var query: Query? {
    didSet {
      if let listener = listener {
        listener.remove()
        observeQuery()
      }
    }
  }

  private var miniPlayer: MiniPlayerViewController?

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
    query = baseQuery()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    setupUser()
    observeQuery()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    authorizeSpeech()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    Auth.auth().removeStateDidChangeListener(userHandle!)
    stopObserving()
  }
  
  deinit {
    Auth.auth().removeStateDidChangeListener(userHandle!)
    listener?.remove()
  }
}

// MARK - Firestore
extension MainViewController {
  // memo: just preping for poc testers

  fileprivate func observeQuery() {
    guard let query = query else { return }
    stopObserving()
    
    listener = query.addSnapshotListener { [unowned self] (snapshot, error) in
      guard let snapshot = snapshot else {
        print("Error fetching snapshot in main")
        return
      }
      
      let models = snapshot.documents.map { (document) -> Room in
        if let model = Room(dictionary: document.data()) {
          return model
        }
        else {
          fatalError("Unable to initialize type \(Room.self) with dictionary \(document.data())")
        }
      }
      self.rooms = models
      self.documents = snapshot.documents
      
      self.collectionView.reloadData()
    }
  }
  
  fileprivate func stopObserving() {
    listener?.remove()
  }
  
  fileprivate func baseQuery() -> Query {
    return Firestore.firestore().collection("rooms").limit(to: 25)
  }
}

// MARK - User
extension MainViewController {
  
  private func setupUser() {
    userHandle = Auth.auth().addStateDidChangeListener { (auth, user) in
      if let user = user {
        self.user = User(
          uid: user.uid,
          displayName: user.displayName,
          photoURL: user.photoURL
        )
      }
    }
  }

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
  
  @IBAction func didTapPopulationButton(_ sender: Any) {
    let db = Firestore.firestore()
//    let settings = db.settings
//    settings.areTimestampsInSnapshotsEnabled = true
//    db.settings = settings
    
    let names = Room.names
    let updates = Room.updates
    let photos = Room.photos
    
    for _ in 0..<3 {
      let name = names[Int(arc4random_uniform(UInt32(names.count)))]
      let updated = updates[Int(arc4random_uniform(UInt32(updates.count)))]
      let photo = photos[Int(arc4random_uniform(UInt32(photos.count)))]
      
      let room = Room(
        name: name,
        updated: updated,
        photo: photo
      )
      
      db.collection("rooms").document(room.name).setData(room.dictionary) { (error) in
        if let error = error {
          print("Error writing document: \(room.name), \(error)")
        }
        else {
          print("Successfully written \(room.name)")
        }
      }
      
      // just trying batch
      let roomRef = db.collection("rooms").document(room.name)
      let batch = Firestore.firestore().batch()
      guard let user = Auth.auth().currentUser else { continue }
      
      let texts = Message.texts
      for i in 0..<texts.count {
        let message = Message(
          senderID: user.uid,
          audio: URL(fileURLWithPath: "moe.m4a"),
          text: texts[i],
          date: Date()
        )
        
        let messageRef = roomRef.collection("messages").document()
        batch.setData(message.dictionary, forDocument: messageRef)
      }
      batch.commit { (error) in
        guard let error = error else { return }
        print("Error generating messages: \(error). Check Firestore permissions.")
      }
    }
  }
  
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
    let room = rooms[indexPath.item]
    
//    if miniPlayer == nil {
//      miniPlayer = MiniPlayerViewController()
//    }
//    miniPlayer?.configure(room: room)
    
    let controller = RoomViewController.fromStoryboard()
    controller.user = user
    controller.room = room
    navigationController?.pushViewController(controller, animated: true)
  }
}

// MARK: - Speech
extension MainViewController {
  
  func authorizeSpeech() {
    SFSpeechRecognizer.requestAuthorization { (authStatus) in
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

