//
//  RoomViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/05.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation
import Speech

extension RoomViewController: StoryboardInstance {
  static var storyboardName: String { return "Main" }
}

class RoomViewController: UIViewController {
  
  // MARK: Properties
  private let audioEngine = AVAudioEngine()
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
  private let request = SFSpeechAudioBufferRecognitionRequest()
  private var recognitionTask: SFSpeechRecognitionTask?
  
  private let inputNodeBus: AVAudioNodeBus = 0
  private var mostRecentlyProcessedSegmentDuration: TimeInterval = 0
  fileprivate var player: AVPlayer?
  
  private var isRecording = false
  private let animationDuration = 3.0

  var user: User! {
    didSet {
      if let user = user {
        print("[user] \(user.uid) \(user.displayName!) entered room")
      }
    }
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  var messages: [Message] = [
    Message(text: "プロフェッショナルとは"),
    Message(text: "ケイスケホンダ"),
    Message(text: "どういうことか"),
    Message(text: "プロフェッショナルを今後ケイスケホンダにしてしまいます"),
    Message(text: "お前ケイスケホンダやな、みたいな"),
  ]
  
  // MARK: IBOutlets
  
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var transcriptOverlayView: UIView!
  @IBOutlet weak var transcriptLabel: UILabel! {
    didSet {
      print("transcriptLabel didSet")
      if let transcript = transcriptLabel.text {
        print(transcript)
      }
      else {
        print("...but transcript.text is empty")
      }
    }
  }
  @IBOutlet weak var transcriptOverlayHeight: NSLayoutConstraint!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setNeedsStatusBarAppearanceUpdate()
    self.title = user?.displayName ?? "Anonymous"
//    navigationController?.navigationBar.barTintColor = UIColor.white
    navigationController?.navigationBar.isTranslucent = false
    navigationController?.navigationBar.barStyle = .black
    navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.white]

    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleCollectionViewTap(recognizer:))))
    
    recordButton.isEnabled = false
    setupUIForRecording()
    authorizeMicrophone()
  }

  @IBAction func onTouchDown(_ sender: UIButton) {
    print("onTouchDown [start recording]")
    // begin recording
    // prompt: slide up to cancel
    startRecording()
    updateUIForTranscriptionInProgress()
  }
  
  @IBAction func onTouchUpInside(_ sender: UIButton) {
    print("onTOuchUpInside [complete recording and send message]")
    // complete recording
    // send message
    stopRecording()
    saveMessage()
    updateUIForCompletedTranscription()
  }
  
  @IBAction func onTouchUpOutside(_ sender: UIButton) {
    print("onTouchUpOutside [cancel recording and trash message]")
    // cancel recording
    // trash message
    recordButton.isEnabled = false
    stopRecording()
  }
  
  @IBAction func onTouchDragInside(_ sender: UIButton) {
    print("onTouchDragInside")
    // do nothing if already same state
    // prompt: slide up to cancel
  }
  
  @IBAction func onTouchDragOutside(_ sender: UIButton) {
    print("onTouchDragOutside")
    // do nothing if already same state
    // prompt: let go to cancel
  }
  
  @objc func handleCollectionViewTap(recognizer: UITapGestureRecognizer) {
    if recognizer.state == .ended {
      print("collectionView has been tapped")
    }
  }
}

// MARK: - Messaging
extension RoomViewController {
  private func saveMessage() {
    if let transcription = transcriptLabel?.text {
      print("Saving Message \(transcription)")
      let message = Message(text: transcription)
      messages.append(message)
      collectionView.reloadData()
    }
  }
}

// MARK: - Live Transcription
extension RoomViewController {
  fileprivate func startRecording() {
    print("startRecording()")
    do {
      self.transcriptLabel?.text = ""
      mostRecentlyProcessedSegmentDuration = 0
      
      let node = audioEngine.inputNode
      let recordingFormat = node.outputFormat(forBus: inputNodeBus)
      
      node.installTap(onBus: inputNodeBus, bufferSize: 1024, format: recordingFormat) { (buffer, time) in
        self.request.append(buffer)
      }
      
      audioEngine.prepare()
      try audioEngine.start()
      
      recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { [unowned self] (result, error) in
        if let error = error {
          print(error.localizedDescription)
        }
        
        if let transcription = result?.bestTranscription {
          self.updateUIWithTranscription(transcription)
        }
      })
    }
    catch let error {
      print("There was a problem in recording: \(error.localizedDescription)")
    }
  }
  
  fileprivate func stopRecording() {
    print("stopRecording()")
    audioEngine.stop()
    request.endAudio()
    audioEngine.inputNode.removeTap(onBus: inputNodeBus)
    recognitionTask?.cancel()
    recordButton?.isEnabled = true
  }
}

// MARK: - UI Management
extension RoomViewController {
  fileprivate func setupUIForRecording() {
    print("updateUIForRecording")
    transcriptLabel?.text = ""
    transcriptOverlayHeight?.constant = 0
    transcriptOverlayView?.isHidden = true
    transcriptLabel?.isHidden = true
    updateUIForCompletedTranscription()
  }
  
  fileprivate func updateUIForTranscriptionInProgress() {
    DispatchQueue.main.async { [unowned self] in
      print("updateUIForTranscriptionInProgress (in main dispatch queue)")
      self.transcriptOverlayHeight?.constant = self.view.bounds.height
      self.transcriptOverlayView?.isHidden = false
      self.transcriptLabel?.isHidden = false
    }
  }
  
//  fileprivate func updateUIWithTranscription() {
//    print("updateUIWithTranscription")
//  }
  
  fileprivate func updateUIWithTranscription(_ transcription: SFTranscription) {
    print("updateUIWithTranscription(_:)")
    transcriptLabel.text = transcription.formattedString
    if let t = transcriptLabel.text {
      print("transcritLabel.text = \(t)")
    }
    else {
      print("transcriptLabel.text is nil")
    }

    if let lastSegment = transcription.segments.last,
      lastSegment.duration > mostRecentlyProcessedSegmentDuration {
      mostRecentlyProcessedSegmentDuration = lastSegment.duration
      print(mostRecentlyProcessedSegmentDuration)
      print(lastSegment.substring)
    }
  }
  
  fileprivate func updateUIForCompletedTranscription() {
    print("updateUIForCompletedTranscription")
    DispatchQueue.main.async { [unowned self] in
      self.transcriptLabel.text = ""
      self.transcriptOverlayHeight?.constant = 0
      self.transcriptOverlayView?.isHidden = true
      self.transcriptLabel?.isHidden = true
      let item = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
      let lastItemIndex = IndexPath(item: item, section: 0)
      self.collectionView?.scrollToItem(at: lastItemIndex, at: UICollectionViewScrollPosition.top, animated: true)
      self.recordButton?.isEnabled = true
    }
  }
  
  fileprivate func updateUIOnTouchDown() {
    print("上にスライドで取り消し")
  }
  
  fileprivate func updateUIOnDragOutside() {
    print("放すと取り消し")
  }
}

extension RoomViewController {
  func authorizeMicrophone() {
//    let authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    SFSpeechRecognizer.requestAuthorization { [unowned self] (authStatus) in
      switch authStatus {
      case .authorized:
        print("Microphone Authorized")
      case .denied:
        print("Microphone Denied")
      case .restricted:
        print("Microphone not available")
      case .notDetermined:
        print("Microphone Not Determined")
      }
    }
  }
}

extension RoomViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MessageCell", for: indexPath) as! MessageCell
    cell.populate(message: messages[indexPath.item])
    return cell
  }
}

extension RoomViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let message = messages[indexPath.item]
    print("Message Tapped \(message.text)")
  }
}

extension RoomViewController: UICollectionViewDelegateFlowLayout {
}

class MessageCell: UICollectionViewCell {
  
  @IBOutlet weak var textLabel: UILabel!
  
  func populate(message: Message) {
    textLabel.text = message.text
  }
}
