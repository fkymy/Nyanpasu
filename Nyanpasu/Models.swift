//
//  Models.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/04.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

struct User {
  
  let uid: String
  let displayName: String?
  let photoURL: URL?
}

struct Room {
  
  let name: String
  let updated: String
  let photo: String
  
  static func all() -> [Room] {
    return [
      Room(name: "fuku", updated: "ユウスケフクヤマ どういう意味...", photo: "profileImage1"),
      Room(name: "アリス", updated: "今日はどんな感じ？やっぱキャンプ...", photo: "profileImage2"),
      Room(name: "カフカ", updated: "Updated Feb 12, 2018", photo: "profileImage3"),
      Room(name: "スティーブ", updated: "Updated Jan 1, 2018", photo: "profileImage4"),
      Room(name: "れんちょん", updated: "Updated Dec 21, 2017", photo: "profileImage5"),
      Room(name: "うっくん", updated: "Updated Dec 21, 2017", photo: "profileImage6"),
      Room(name: "百合子", updated: "Updated Dec 21, 2017", photo: "profileImage7"),
      Room(name: "れんちょん", updated: "Updated Dec 21, 2017", photo: "profileImage1"),
      Room(name: "うっくん", updated: "Updated Dec 21, 2017", photo: "profileImage2"),
      Room(name: "百合子", updated: "Updated Dec 21, 2017", photo: "profileImage3"),
    ]
  }
  
  static func randomImage() -> UIImage {
    let randomIndex = Int(arc4random_uniform(UInt32(images.count)))
    let image = UIImage(named: images[randomIndex])!
    return image
  }
  
  static let images = [
    "profileImage1",
    "profileImage2",
    "profileImage3",
    "profileImage4",
    "profileImage5",
    "profileImage6",
    "profileImage7",
  ]
}

struct Message {
  let text: String
}
