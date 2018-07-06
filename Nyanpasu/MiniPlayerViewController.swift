//
//  MiniPlayerViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/05.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

class MiniPlayerViewController: UIViewController {
  
  var currentRoom: Room?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configure(room: nil)
  }
  
  func configure(room: Room?) {
    if let room = room {
      name.text = room.name
      thumbImage.image = UIImage(named: room.photo)
    }
    else {
      name.text = "れんちょん"
      thumbImage.image = UIImage(named: "kuchi")
    }
    
    currentRoom = room
  }
  
  @IBOutlet weak var thumbImage: UIImageView!
  @IBOutlet weak var name: UILabel!
  @IBOutlet weak var playButton: UIButton!
}
