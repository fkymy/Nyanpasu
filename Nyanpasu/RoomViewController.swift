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

//enum AudioStatus: Int {
//  case stopped = 0,
//  playing,
//  recording
//}

class RoomViewController: UIViewController {
  
  // MARK: Properties
  // av
  private let session = AVAudioSession.sharedInstance()
  private var audioEngine: AVAudioEngine!
  private var audioPlayer: AVAudioPlayer!
//  private var audioMixer: AVAudioMixerNode!
  private var outref: ExtAudioFileRef?
  private var filePath: String? = nil
  // sf
  private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
  private let request = SFSpeechAudioBufferRecognitionRequest()
  private var recognitionTask: SFSpeechRecognitionTask?
  private let inputNodeBus: AVAudioNodeBus = 0
  private var mostRecentlyProcessedSegmentDuration: TimeInterval = 0
  // fs
  private let storage = Storage.storage(url: "gs://nyanpasu-7767d.appspot.com")
  private var listener: ListenerRegistration?
  fileprivate var query: Query? {
    didSet {
      if let listener = listener {
        listener.remove()
        observeQuery()
      }
    }
  }

  var user: User! {
    didSet {
      if let user = user {
        print("[user] \(user.uid) \(user.displayName!) entered room")
      }
    }
  }
  
  var room: Room! {
    didSet {
      if let room = room {
        print("room has been set to \(room.name)")
      }
    }
  }
  private var messages: [Message] = []
  private var documents: [DocumentSnapshot] = []
  
  // ut
  private var initiatationFeedbackGenerator: UIImpactFeedbackGenerator? = nil
  private var successFeedbackGenerator: UINotificationFeedbackGenerator? = nil

//  var messages: [Message] = [
//    Message(text: "プロフェッショナルとは"),
//    Message(text: "ケイスケホンダ"),
//    Message(text: "どういうことか"),
//    Message(text: "プロフェッショナルを今後ケイスケホンダにしてしまいます"),
//    Message(text: "お前ケイスケホンダやな、みたいな"),
//  ]
  
  private func setupAudioEngine() {
    audioEngine = AVAudioEngine()
//    audioPlayer.delegate = self
  }
  
  fileprivate func baseQuery() -> Query {
    let db = Firestore.firestore()
    let ref = db.collection("rooms").document(room.name).collection("messages")
    return ref.order(by: "date", descending: false).limit(to: 30)
  }
  
  fileprivate func observeQuery() {
    guard let query = query else { return }
    stopObserving()
    
    listener = query.addSnapshotListener { [unowned self] (snapshot, error) in
      guard let snapshot = snapshot else {
        print("Error fetching snapshot in room:")
        return
      }
      
      let models = snapshot.documents.map { (document) -> Message in
        var dictionary = document.data()
        dictionary["id"] = document.documentID
        if let model = Message(dictionary: dictionary) {
          return model
        }
        else {
          // tmp for dev
          fatalError("Unable to initialize Message with dictionary \(document.data())")
        }
      }
      self.messages = models
      self.documents = snapshot.documents
      
      self.collectionView.reloadData()
      self.setupUIForRecording()
    }
  }
  
  fileprivate func stopObserving() {
    listener?.remove()
  }
  
  // MARK: IBOutlets
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var recordButtonHeight: NSLayoutConstraint!
  @IBOutlet weak var recordButtonWidth: NSLayoutConstraint!
  @IBOutlet weak var transcriptOverlayView: UIView!
  @IBOutlet weak var transcriptLabel: UILabel!
  @IBOutlet weak var transcriptOverlayHeight: NSLayoutConstraint!
  
  // MARK: Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.setNeedsStatusBarAppearanceUpdate()
    self.title = user?.displayName ?? "Anonymous"
    navigationController?.navigationBar.isTranslucent = false
    navigationController?.navigationBar.barStyle = .black
    navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.white]

    collectionView.dataSource = self
    collectionView.delegate = self

    recordButton.layer.shadowColor = UIColor.white.cgColor
    recordButton.layer.shadowOffset = CGSize.zero
    recordButton.layer.shadowOpacity = 0.4
    recordButton.isEnabled = false
    
    initiatationFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    initiatationFeedbackGenerator?.prepare()
    successFeedbackGenerator = UINotificationFeedbackGenerator()
    successFeedbackGenerator?.prepare()

    query = baseQuery()
    observeQuery()
    setupAudioEngine()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
   
    authorizeMicrophone()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    initiatationFeedbackGenerator = nil
    successFeedbackGenerator = nil
    deactivateAudio()
    stopRecording()
    stopObserving()
  }
  
  deinit {
    deactivateAudio()
    stopRecording()
    listener?.remove()
  }
}

// MARK: - IBActions
extension RoomViewController {
 
  @IBAction func onTouchDown(_ sender: UIButton) {
    print("onTouchDown [start recording]")
    // - begin recording
    // - prompt: slide up to cancel
    startRecording()
    updateUIForTranscriptionInProgress()
  }
  
  @IBAction func onTouchUpInside(_ sender: UIButton) {
    print("onTOuchUpInside [complete recording and send message]")
    // - complete recording
    // - send message
    stopRecording()
    saveMessage()
    updateUIForCompletedTranscription()
    successFeedbackGenerator?.notificationOccurred(.success)
  }
  
  @IBAction func onTouchUpOutside(_ sender: UIButton) {
    print("onTouchUpOutside [cancel recording and trash message]")
    // - cancel recording
    // - trash message
    recordButton.isEnabled = false
    stopRecording()
    updateUIForCompletedTranscription()
  }
  
  @IBAction func onTouchDragInside(_ sender: UIButton) {
    print("onTouchDragInside")
    // - do nothing if already same state
    // - prompt: slide up to cancel
  }
  
  @IBAction func onTouchDragOutside(_ sender: UIButton) {
    print("onTouchDragOutside")
    // - do nothing if already same state
    // - prompt: let go to cancel
  }
}

// MARK: - Messaging
extension RoomViewController {
  
  private func saveMessage() {
    guard let transcription = transcriptLabel?.text else {
      print("there is no transcription..")
      return
    }
    
    // messages.append(message)
    // collectionView.reloadData()
    
    let documentRef = Firestore.firestore().collection("rooms").document(room.name).collection("messages").document()
    let audioFilename = documentRef.documentID
    documentRef.setData(["senderId": user.uid,
                         "text": transcription,
                         "date": Date(),
                         "audio": documentRef.documentID])
    
    uploadAudio(string: audioFilename)
  }
}

// MARK: - Audio
extension RoomViewController: AVAudioPlayerDelegate {
  
  private func activateAudio() {
    do {
      // - configure audio session category, options, and mode
      // - activate your audio session to enable your custom configuration
      // ! for now, default input and output only
      try session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.defaultToSpeaker)
      try session.setActive(true)
    }
    catch let error {
      print("Unable to activate audio session: \(error.localizedDescription)")
    }
  }
  
  private func deactivateAudio() {
    do {
      try session.setActive(false)
    }
    catch {
      print("Error deactivating audio")
    }
  }
  
  private func play(contentsOf message: Message) {
    print("play(message: \(message.description)")
//    let audioRef = storage.reference().child("audio").child(message.id)
    let audioRef = storage.reference().child("audio").child(message.audio.absoluteString)
    audioRef.getData(maxSize: 1*4096*4096) { [weak self] (data, error) in
      guard let strongSelf = self else { return }
      if let error = error {
        print(error.localizedDescription)
      }
      guard let data = data else {
        print("no data from ref: \(audioRef.description)")
        return
      }
      print("geData returned data: \(data.description)")
      strongSelf.activateAudio()
      
      do {
        print("playing audioPlayer")
        strongSelf.audioPlayer = try AVAudioPlayer.init(data: data)
        strongSelf.audioPlayer.delegate = self
        strongSelf.audioPlayer.play()
//        strongSelf.audioStatus = .playing
      }
      catch {
        print("audioPlayer failed, from data \(data.description)")
        strongSelf.audioPlayer = nil
//        strongSelf.audioStatus = .stopped
      }
    }
  }
  
  private func stopPlayback() {
    audioPlayer.stop()
//    audioStatus = .stopped
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    print("audioPlayerDidFinishPlaying")
    print("successfully \(flag.description)")
//    audioStatus = .stopped
  }
  
  private func uploadAudio(string: String) {
    print("Uploading audio with filename \(string)")
    
    let ref = storage.reference().child("audio")
    let filename = string
    
    let url = getUrlForAudio()
    let data = try? Data(contentsOf: url)
    if let data = data {
      let uploadTask = ref.child(filename).putData(data, metadata: nil) { (metadata, error) in
        guard let metadata = metadata else {
          print("error uploading")
          return
        }
        print(metadata.description)
      }
      uploadTask.resume()
    }
    else {
      print("no data to save...")
    }
  }
  
  private func getUrlForAudio() -> URL {
//    let dir = NSTemporaryDirectory()
    let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
    filePath = dir + "/tmp_audio.caf"
    return URL(fileURLWithPath: filePath!)
  }
  
  private func getFilePathForAudio() -> String {
    let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
    return dir + "/tmp_audio.caf"
  }
  
  private func removeFileForAudio() {
    let manager = FileManager.default
    let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first! as URL
    let path = url.appendingPathComponent("tmp_audio.m4a").path
    if manager.fileExists(atPath: path) {
      try! manager.removeItem(atPath: path)
    }
  }
}

// MARK: - Speech
extension RoomViewController {
  
  fileprivate func authorizeMicrophone() {
    SFSpeechRecognizer.requestAuthorization { (authStatus) in
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

  fileprivate func startRecording() {
    print("startRecording()")
    initiatationFeedbackGenerator?.impactOccurred()
    
    do {
      print("transcriptLabel \(self.transcriptLabel!.text)")
      self.transcriptLabel?.text = ""
      mostRecentlyProcessedSegmentDuration = 0
      
      // workaround for preventing initialization of multiple audio units.
      // AudioOutputUnitStop(audioEngine.inputNode.audioUnit!)
      // AudioUnitUninitialize(audioEngine.inputNode.audioUnit!)
      activateAudio()
//      let engine = AVAudioEngine()
      let inputNode = audioEngine.inputNode
      print("inputNode set \(inputNode.description)")
//      let mixerNode = engine.mainMixerNode

      let formatSettings: [String: Any] = [
        AVSampleRateKey: 441000.0,
        AVNumberOfChannelsKey: 1,
        AVFormatIDKey: Int(kAudioFormatLinearPCM), // mono recording
        AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
      ]
      
      let recordingFormat = inputNode.outputFormat(forBus: inputNodeBus)
      print("recordingFormat: \(recordingFormat)")

//      audioEngine.connect(inputNode, to: mixerNode, format: recordingFormat)
//      let recordingFormatSettings = recordingFormat.dictionaryWithValues(forKeys: [AVSampleRateKey, AVNumberOfChannelsKey, AVFormatIDKey, AVEncoderAudioQualityKey])

      let url = getUrlForAudio()
      let outputFile = try AVAudioFile(forWriting: url, settings: recordingFormat.settings)
      print("outputFile \(outputFile.description)")

      inputNode.installTap(onBus: inputNodeBus, bufferSize: 1024, format: inputNode.inputFormat(forBus: 0)) { (buffer, time) in
        print(buffer.description)
        self.request.append(buffer)
        
        do {
          try outputFile.write(from: buffer)
        }
        catch let error {
          print(error.localizedDescription)
        }
      }
      
      recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { [unowned self] (result, error) in
        if let error = error {
          print(error.localizedDescription)
        }
        
        if let transcription = result?.bestTranscription {
          self.updateUIWithTranscription(transcription)
        }
      })

//
//      let tmpUrl = getUrlForAudio()
//      _ = ExtAudioFileCreateWithURL(tmpUrl as CFURL, kAudioFileCAFType, (format?.streamDescription)!, nil, AudioFileFlags.eraseFile.rawValue, &outref)
//
//      mixerNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount((format?.sampleRate)!*0.4), format: recordingFormat) { (buffer, time) in
//        let audioBuffer = buffer as AVAudioBuffer
//        _ = ExtAudioFileWrite(self.outref!, buffer.frameLength, audioBuffer.audioBufferList)
//      }
      
      audioEngine.prepare()
      print("isRunning \(audioEngine.isRunning.description)")
      try audioEngine.start()
    }
    catch let error {
      print("There was a problem in recording: \(error.localizedDescription)")
    }
  }
  
  fileprivate func stopRecording() {
    print("stopRecording()")
//    audioEngine.mainMixerNode.removeTap(onBus: inputNodeBus)
    audioEngine.inputNode.removeTap(onBus: inputNodeBus)
    audioEngine.stop()
    deactivateAudio()
    
    request.endAudio()
    recognitionTask?.cancel()
//    ExtAudioFileDispose(outref!)
  }
}

// MARK: - UI Management
extension RoomViewController {
  
  fileprivate func setupUIForRecording() {
    print("updateUIForRecording")
    DispatchQueue.main.async { [unowned self] in
      self.transcriptLabel.text = ""
      self.recordButtonHeight?.constant = 48
      self.recordButtonWidth?.constant = 160
      self.transcriptOverlayHeight?.constant = 0
      self.transcriptOverlayView?.isHidden = true
      self.transcriptLabel?.isHidden = true
      let item = self.collectionView(self.collectionView!, numberOfItemsInSection: 0) - 1
      let lastItemIndex = IndexPath(item: item, section: 0)
      self.collectionView?.scrollToItem(at: lastItemIndex, at: UICollectionViewScrollPosition.top, animated: true)
      self.recordButton?.isEnabled = true
    }
  }
  
  fileprivate func updateUIForTranscriptionInProgress() {
    DispatchQueue.main.async { [unowned self] in
      print("updateUIForTranscriptionInProgress (in main dispatch queue)")
      self.recordButtonHeight?.constant = 48 * 1.2
      self.recordButtonWidth?.constant = 160 * 1.2
      self.transcriptOverlayHeight?.constant = self.view.bounds.height
      self.transcriptOverlayView?.isHidden = false
      self.transcriptLabel?.isHidden = false
    }
  }
  
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
    setupUIForRecording()
  }
  
  fileprivate func updateUIOnTouchDown() {
    print("上にスライドで取り消し")
  }
  
  fileprivate func updateUIOnDragOutside() {
    print("放すと取り消し")
  }
}

// MARK: - UICollectionViewDataSource
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

// MARK: - UICollectionViewDelegate
extension RoomViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let message = messages[indexPath.item]
    print("Message Tapped \(message.text)")
    // switch on status
    play(contentsOf: message)
  }
}

extension RoomViewController: UICollectionViewDelegateFlowLayout {
  // - get intrinsic size from transcript text
}

// MARK: - Message cell
class MessageCell: UICollectionViewCell {
  @IBOutlet weak var textLabel: UILabel!
  func populate(message: Message) {
    textLabel.text = message.text
  }
}
