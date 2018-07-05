//
//  Models.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/04.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import Foundation

struct User {
  
  let uid: String
  let displayName: String?
  let photoURL: URL?
}

struct Room {
  
  let name: String
  let updated: String
  var isUpdated: Bool
  
  static func all() -> [Room] {
    return [
      Room(name: "Alice", updated: "Updated July 3, 2018", isUpdated: false),
      Room(name: "Kafka", updated: "Updated July 3, 2018", isUpdated: false),
      Room(name: "Steve", updated: "Updated July 3, 2018", isUpdated: false),
      Room(name: "れんちょん", updated: "Updated July 3, 2018", isUpdated: false),
    ]
  }
}

struct Message {
  let text: String
}
