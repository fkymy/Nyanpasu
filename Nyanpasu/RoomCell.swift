//
//  RoomCell.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/04.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit

class RoomCell: UICollectionViewCell {
  public static let identifier = "RoomCell"
  
  var room: Room? {
    didSet {
      print("room was set")
      nameLabel.text = room?.name
      updatedLabel.text = room?.updated
    }
  }
  
  let bubbleView: UIView = {
    let view = UIView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = UIColor.secondaryBackgroundColor
    view.layer.cornerRadius = 20
    view.layer.masksToBounds = true
    return view
  }()
  
  let nameLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor.white
    label.textAlignment = .left
    label.font = UIFont.systemFont(ofSize: 16)
    return label
  }()
  
  let updatedLabel: UILabel = {
    let label = UILabel()
    label.textColor = UIColor.lightGray
    label.textAlignment = .left
    label.font = UIFont.systemFont(ofSize: 14)
    return label
  }()
  
  lazy var stackView: UIStackView = {
    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = UILayoutConstraintAxis.vertical
    stackView.distribution = UIStackViewDistribution.equalSpacing
    stackView.alignment = UIStackViewAlignment.center
    stackView.spacing = 4.0
    stackView.addArrangedSubview(self.nameLabel)
    stackView.addArrangedSubview(self.updatedLabel)
    return stackView
  }()
  
  let profileImageView: UIImageView = {
    let imageView = UIImageView()
    return imageView
  }()
  
  override func prepareForReuse() {
    super.prepareForReuse()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(bubbleView)
    addSubview(stackView)
    
    let bubbleViewTop = bubbleView.topAnchor.constraint(equalTo: self.topAnchor)
    let bubbleViewLeft = bubbleView.leftAnchor.constraint(equalTo: self.leftAnchor)
    let bubbleViewright = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor)
    let bubbleViewBottom = bubbleView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
    NSLayoutConstraint.activate([
      bubbleViewTop, bubbleViewLeft, bubbleViewright, bubbleViewBottom
      ])
    
    let stackViewCenterX = stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
    let stackViewCenterY = stackView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
    NSLayoutConstraint.activate([stackViewCenterX, stackViewCenterY])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
