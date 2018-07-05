//
//  StudioViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/04.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import Firebase

extension StudioViewController: StoryboardInstance {
  static var storyboardName: String { return "Main" }
}

class StudioViewController: UIViewController {
  
  // MARK: Properties
  var user: User! {
    didSet {
      if let user = user {
        print("[user] \(user.uid) \(user.displayName!) entered studio")
      }
    }
  }
  
  var messages: [Message] = []
  
  // MARK: IBOutlets
  
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var inputPanelView: UIView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = user?.displayName ?? "Anonymous"
//    navigationController?.navigationBar.barTintColor = UIColor.red
//    navigationController?.navigationBar.isTranslucent = false
//    navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.white]
    
    collectionView.dataSource = self
    collectionView.delegate = self
    
    inputPanelView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleInput(recognizer:))))
  }
  
  @objc func handleInput(recognizer: UIGestureRecognizer) {
    if recognizer.state == .began {
      print("Long press from user \(user!.displayName!)")
    }
  }
}

extension StudioViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCell", for: indexPath) as! MessageCell
    cell.populate(message: messages[indexPath.item])
    return cell
  }
}

extension StudioViewController: UICollectionViewDelegate {
  
}

extension StudioViewController: UICollectionViewDelegateFlowLayout {
  
}

//class MessageCell: UICollectionViewCell {
//  
//  @IBOutlet weak var textLabel: UILabel!
//
//  func populate(message: Message) {
//    textLabel.text = "hello"
//  }
//}
