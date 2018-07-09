//
//  Models.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/04.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

protocol DocumentSerializable {
  init?(dictionary: [String: Any])
}

struct User {
  
  let uid: String
  let displayName: String?
  let photoURL: URL?
}

struct Room {
  
  var name: String
  var updated: String
  var photo: String
  
  var dictionary: [String: Any] {
    return [
      "name": name,
      "updated": updated,
      "photo": photo
    ]
  }

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
    let randomIndex = Int(arc4random_uniform(UInt32(photos.count)))
    let image = UIImage(named: photos[randomIndex])!
    return image
  }
  
  static let names = [
    "fuku", "アリス", "カフカ", "スティーブ",
    "れんちょん", "うっくん", "百合子", "ケイスケホンダ",
    "田中", "hiromu", "じゅんや", "サミュエル", "いちご",
    "fkymy", "hello", "amigo", "amity", "amitani"
  ]
  
  static let updates = [
    "ユウスケフクヤマ どういう意味...",
    "今日はどんな感じ？やっぱキャンプ...",
    "あの焼き肉ほんとおいしかった...",
    "Be ケイスケホンダ",
    "まじユウスケフクヤマ",
    "まじユウスケフクヤマ",
    "Updated Feb 12, 2018",
    "Updated Jan 1, 2018",
    "Updated Dec 21, 2017"
  ]
  
  static let photos = [
    "profileImage1",
    "profileImage2",
    "profileImage3",
    "profileImage4",
    "profileImage5",
    "profileImage6",
    "profileImage7",
  ]
}

extension Room: DocumentSerializable {
  
  init?(dictionary: [String: Any]) {
    guard let name = dictionary["name"] as? String,
      let updated = dictionary["updated"] as? String,
      let photo = dictionary["photo"] as? String else { return nil }
    
    self.init(name: name, updated: updated, photo: photo)
  }
}

struct Message {
  
  var id: String
  var senderID: String
  var audio: URL
  var text: String
  var date: Date
  
  var dictionary: [String: Any] {
    return [
      "senderId": senderID,
      "audio": audio.absoluteString,
      "text": text,
      "date": date
    ]
  }
  
  static let texts = [
    "プロフェッショナルとは",
    "ケイスケホンダ",
    "どういうことか",
    "プロフェッショナルを今後ケイスケホンダにしてしまいます",
    "お前ケイスケホンダやな、みたいな"
  ]
}

extension Message: DocumentSerializable {
  
  init?(dictionary: [String: Any]) {
    guard let id = dictionary["id"] as? String,
      let senderID = dictionary["senderId"] as? String,
      let text = dictionary["text"] as? String,
      let date = dictionary["date"] as? Date,
      let audio = (dictionary["audio"] as? String).flatMap(URL.init(string:)) else { return nil}
    
    self.init(id: id, senderID: senderID, audio: audio, text: text, date: date)
  }
}

extension Message: CustomStringConvertible {
  var description: String {
    return "Message \(id) <senderID: \(senderID), audio: \(audio.absoluteString), text: \(text), data: \(date)>"
  }
}
