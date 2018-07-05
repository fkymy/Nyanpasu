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
      profileImageView.image = Room.randomImage()
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
  
  let profileImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "kuchi")
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.layer.cornerRadius = 27
    imageView.layer.masksToBounds = true
    imageView.contentMode = .scaleAspectFill
    return imageView
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
  
  lazy var labelStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = UILayoutConstraintAxis.vertical
    stackView.distribution = UIStackViewDistribution.equalSpacing
    stackView.alignment = UIStackViewAlignment.leading
    stackView.spacing = 4.0
    
    stackView.addArrangedSubview(self.nameLabel)
    stackView.addArrangedSubview(self.updatedLabel)
    return stackView
  }()
  
  let playButton: UIButton = {
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("", for: .normal)
    button.setTitleColor(UIColor.white, for: .normal)
    button.setImage(UIImage(named: "play")!, for: .normal)
    button.tintColor = UIColor.white
    return button
  }()

  lazy var horizontalStackView: UIStackView = {
    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = UILayoutConstraintAxis.vertical
    stackView.distribution = UIStackViewDistribution.equalSpacing
    stackView.alignment = UIStackViewAlignment.leading
    stackView.spacing = 4.0
    return stackView
  }()
  
  override func prepareForReuse() {
    super.prepareForReuse()
    // sd_cancelCurrentImageLoad()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    addSubview(bubbleView)
    addSubview(profileImageView)
    addSubview(labelStackView)
    addSubview(playButton)
    
    let bubbleViewTop = bubbleView.topAnchor.constraint(equalTo: self.topAnchor)
    let bubbleViewLeft = bubbleView.leftAnchor.constraint(equalTo: self.leftAnchor)
    let bubbleViewright = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor)
    let bubbleViewBottom = bubbleView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
    NSLayoutConstraint.activate([bubbleViewTop, bubbleViewLeft, bubbleViewright, bubbleViewBottom])
    
    let profileImageViewCenterY = profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
    let profileImageViewLeft = profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16)
    let profileImageViewWidth = profileImageView.widthAnchor.constraint(equalToConstant: 54)
    let profileImageViewHeight = profileImageView.heightAnchor.constraint(equalToConstant: 54)
    NSLayoutConstraint.activate([profileImageViewCenterY, profileImageViewLeft, profileImageViewWidth, profileImageViewHeight])
    
    let labelStackViewLeft = labelStackView.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 16)
    let labelStackViewRight = labelStackView.rightAnchor.constraint(equalTo: playButton.leftAnchor, constant: 16)
    let labelStackViewCenterY = labelStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor)
    NSLayoutConstraint.activate([labelStackViewLeft, labelStackViewRight, labelStackViewCenterY])
    
    let playButtonRight = playButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16)
    let playButtonCenterY = playButton.centerYAnchor.constraint(equalTo: self.centerYAnchor)
    NSLayoutConstraint.activate([playButtonRight, playButtonCenterY])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
