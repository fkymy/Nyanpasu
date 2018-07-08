//
//  StudioViewController.swift
//  Nyanpasu
//
//  Created by Yuske Fukuyama on 2018/07/04.
//  Copyright © 2018 Yuske Fukuyama. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import Firebase

extension StudioViewController: StoryboardInstance {
  static var storyboardName: String { return "Main" }
}

enum AudioStatus: Int, CustomStringConvertible {
  case stopped = 0,
  playing,
  recording
  
  var statusString: String {
    let status = [
      "Audio: Stopped",
      "Audio: Playing",
      "Audio: Recording"
    ]
    return status[rawValue]
  }
  
  var description: String {
    return statusString
  }
}

class StudioViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
  
  // MARK: Properties
  let storage = Storage.storage(url: "gs://nyanpasu-7767d.appspot.com")
  var listener: ListenerRegistration?
  var audios: [String] = []
  var documents: [DocumentSnapshot] = []

  let session = AVAudioSession.sharedInstance()
  var audioEngine: AVAudioEngine!
  var mixer: AVAudioMixerNode!
  var audioFile: AVAudioFile!
  var audioFilePlayer: AVAudioPlayerNode!
  var outref: ExtAudioFileRef?
  var filePath: String? = nil
  
  var audioStatus = AudioStatus.stopped
  var audioRecorder: AVAudioRecorder!
  var audioPlayer: AVAudioPlayer!
  
  var isPlaying = false
  var isRecording = false
  
//  var recorder: AVAudioRecorder?
//
//  // MARK: IBOutlets
//  @IBAction func toggleRecorder() {
//    guard let recorder = recorder else { return }
//    if recorder.isRecording {
//      recorder.stop()
//    }
//    else {
//      recorder.record()
//      // provide feedback using meters
//    }
//  }
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var recordButton: UIButton!
  @IBOutlet weak var recordButtonHeight: NSLayoutConstraint!
  @IBOutlet weak var recordButtonWidth: NSLayoutConstraint!

  private func setupAudioEngine() {
    audioEngine = AVAudioEngine()
    audioFilePlayer = AVAudioPlayerNode()
    mixer = AVAudioMixerNode()
  }
  
  private func setupRecorder() {
    let fileUrl = getUrlForAudio()
    let recordSettings: [String: Any] = [
      AVFormatIDKey: Int(kAudioFormatLinearPCM),
      AVSampleRateKey: 44100.0,
      AVNumberOfChannelsKey: 1, // mono recording
      AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
    ]
    
    do {
      audioRecorder = try AVAudioRecorder(url: fileUrl, settings: recordSettings)
      audioRecorder.delegate = self
      audioRecorder.prepareToRecord()
    }
    catch {
      fatalError("Error setting up recorder") // rm
    }
  }
  
  fileprivate func observe() {
    let db = Firestore.firestore()
    let ref = db.collection("studio")
    stopObserving()
    
    listener = ref.addSnapshotListener{ [unowned self] (snapshot, error) in
      guard let snapshot = snapshot else {
        print("Error fetching snapshot in room")
        return
      }
      
      self.audios = snapshot.documents.map { (document) -> String in
        let dict = document.data()
        if let name = dict["name"] as? String {
          return name
        }
        else {
          fatalError("Unable to init document \(document.data())")
        }
      }
      self.documents = snapshot.documents
      self.tableView.reloadData()
    }
  }
  
  fileprivate func stopObserving() {
    listener?.remove()
  }

  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    setupRecorder()
    setupAudioEngine()
    
    tableView.delegate = self
    tableView.dataSource = self
    
    navigationController?.navigationBar.isTranslucent = false
    navigationController?.navigationBar.barStyle = .black
    navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.white]
    
    observe()
    
    // brutallyTestStorage()
    
    // AVAudioRecorder Example
    // setup AVAudioSession(PlayAndRecord); user permission; input selection

//    do {
//      let formatSettings: [String: Any] = [AVSampleRateKey: 441000.0,
//                                           AVNumberOfChannelsKey: 1,
//                                           AVFormatIDKey: Int(kAudioFormatLinearPCM),
//                                           AVEncoderBitRateKey: 192000,
//                                           AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
//      let recorder = try AVAudioRecorder.init(url: <#T##URL#>, settings: <#T##[String : Any]#>)
//      recorder.prepareToRecord()
//    }
    
    // start here
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    deactivateAudio()
    stopObserving()
  }
  
  deinit {
    deactivateAudio()
    stopObserving()
  }

  @IBAction func onTouchDown(_ sender: UIButton) {
    print("onTouchDown [start recording]")
    switch audioStatus {
    case .stopped:
      simpleRecord()
      updateUIForStartRecording()
    case .playing:
      // - do a stop and record
      // see why audidDidFinishPlaying is not being called on consecutive taps
      stopPlayback()
      simpleRecord()
      updateUIForStartRecording()
    default:
      return
    }
  }
  
  @IBAction func onTouchUpInside(_ sender: UIButton) {
    print("onTOuchUpInside [complete recording and send message]")
//    stopRecording()
    switch audioStatus {
    case .recording:
      stopSimpleRecord()
      saveRecording()
      updateUIForStopRecording()
    default:
      return
    }
  }
  
  @IBAction func onTouchUpOutside(_ sender: UIButton) {
    print("onTouchUpOutside [cancel recording and trash message]")
//    stopRecording()
    switch audioStatus {
    case .recording:
      stopSimpleRecord()
      updateUIForStopRecording()
    default:
      return
    }
  }
  
  private func simpleRecord() {
    audioRecorder.record()
    audioStatus = .recording
  }
  
  private func stopSimpleRecord() {
    audioRecorder.stop()
    audioStatus = .stopped
  }
  
  private func startRecording() {
    filePath = nil
    isRecording = true
    activateAudio()
    
//    audioFile = try! AVAudioFile(forReading: Bundle.main.url(forResource: "moe", withExtension: "m4a")!)
    
    let format = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatInt16, sampleRate: 44100.0, channels: 1, interleaved: true)
    
    audioEngine.attach(mixer)
    audioEngine.connect(audioEngine.inputNode, to: mixer, format: format)
    audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: format)
    
    let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
    filePath =  dir.appending("/studio.caf")

    _ = ExtAudioFileCreateWithURL(URL(fileURLWithPath: filePath!) as CFURL, kAudioFileCAFType, (format?.streamDescription)!, nil, AudioFileFlags.eraseFile.rawValue, &outref)
    
    mixer.installTap(onBus: 0, bufferSize: AVAudioFrameCount((format?.sampleRate)! * 0.4), format: format) { (buffer: AVAudioPCMBuffer, time: AVAudioTime) in
      let audioBuffer = buffer as AVAudioBuffer
      _ = ExtAudioFileWrite(self.outref!, buffer.frameLength, audioBuffer.audioBufferList)
    }
    
    do {
      try audioEngine.start()
    }
    catch {
      print("fuck...")
    }
  }
  
  private func stopRecording() {
    print("stopRecording()")
    isRecording = false
    audioEngine.stop()
    mixer.removeTap(onBus: 0)
    ExtAudioFileDispose(outref!)
    deactivateAudio()
  }
  
  private func playAudio(for index: Int) {
    print("playAudio for \(index)")
//    activateAudio()
//    isPlaying = true
//    let fileUrl = getUrlForAudio()
//    do {
//      audioPlayer = try AVAudioPlayer(contentsOf: fileUrl)
//      audioPlayer.delegate = self
//      if audioPlayer.duration > 0.0 {
//        audioPlayer.volume = 0.5
//        audioPlayer.prepareToPlay()
//      }
//    }
//    catch {
//      isPlaying = false
//      print("failed to init audio player")
//    }
//    if isPlaying == true {
//      audioPlayer.play()
//      audioStatus = .playing
//    }
    
    let audioName = audios[index]
    let audioRef = storage.reference().child("studio").child(audioName)
    audioRef.getData(maxSize: 1*1024*1024) { [weak self] (data, error) in
      guard let strongSelf = self else { return }
      guard let data = data else {
        print("no data from ref: \(audioRef.description)")
        return
      }
      print("getData returned data: \(data.description)")
      strongSelf.activateAudio()
      strongSelf.isPlaying = true
      
      // load for metering...
      do {
        strongSelf.audioPlayer = try AVAudioPlayer(data: data)
        strongSelf.audioPlayer.delegate = self
        if strongSelf.isPlaying == true { // see why, for flagging?/?
          print("play() is called, for audioPlayer \(strongSelf.audioPlayer.description)")
          strongSelf.audioPlayer.play()
          strongSelf.audioStatus = .playing
        }
      }
      catch {
        print("audioPlayer failed, from data \(data.description)")
        strongSelf.audioPlayer = nil
        strongSelf.isPlaying = false
        strongSelf.audioStatus = .stopped
      }
    }
  }
  
  private func stopPlayback() {
    audioPlayer.stop()
    audioStatus = .stopped
  }

  private func saveRecording() {
    let storageRef = storage.reference()
    let studioRef = storageRef.child("studio")
    let filename = "NYANPASU_\(Date().timeIntervalSince1970).caf"
    let url = getUrlForAudio()
    
    let data = try? Data(contentsOf: url)
    if let data = data {
      let uploadTask = studioRef.child(filename).putData(data, metadata: nil) { [weak self] (metadata, error) in
        guard let metadata = metadata else {
          print("error uploading")
          return
        }
        print(metadata.description)
        // self?.audios.append(metadata.name!)
        Firestore.firestore().collection("studio").document(metadata.name!).setData(["name": filename])
        DispatchQueue.main.async {
          self?.tableView.reloadData()
        }
      }
      uploadTask.resume()
    }
    else {
      print("no data to save")
    }
  }
  
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    print("audioPlayerDidFinishPlaying!")
    isPlaying = false
//    audioPlayer.stop()
    deactivateAudio()
  }
  
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    print("audioRecorderDidFinishRecording")
    audioStatus = .stopped
  }
  
  private func setupUI() {
    recordButtonWidth?.constant = 160
    recordButtonHeight?.constant = 48
    recordButton?.isEnabled = true
  }

  private func updateUIForStartRecording() {
    recordButtonWidth?.constant = 160 * 1.3
    recordButtonHeight?.constant = 48 * 1.3
  }
  
  private func updateUIForStopRecording() {
    recordButtonWidth?.constant = 160
    recordButtonHeight?.constant = 48
  }
  
  func activateAudio() {
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
  
  func deactivateAudio() {
    do {
      try session.setActive(false)
    }
    catch {
      print("Error deactivating audio")
    }
  }
}

// MARK: - Audio


// MARK: - TableView
extension StudioViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return audios.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultCell", for: indexPath)
    cell.textLabel?.text = audios[indexPath.row]
    return cell
  }
}

extension StudioViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    print("tableView \(indexPath.row) did select.")
    
    switch audioStatus {
    case .stopped:
      print("audioStatus is .stopped playing audio")
      playAudio(for: indexPath.row)
    case .playing:
      print("audioStatus is .playing playing audio")
      stopPlayback()
      playAudio(for: indexPath.row)
    case .recording:
      print("cannot play when recording..?")
    default:
      return
    }
  }
}

// MARK: - Utilities
extension StudioViewController {
  func getUrlForAudio() -> URL {
    let dir = NSTemporaryDirectory()
    filePath =  dir + "/tmp_studio.caf"
    
    return URL(fileURLWithPath: filePath!)
  }
}

// MARK: - Brutally Test Storage
extension StudioViewController {
  func brutallyTestStorage() {
    let storageRef = storage.reference()
    let filename = "test-\(Date().timeIntervalSince1970).m4a"
    let audioRef = storageRef.child("audio")
    let testAudioRef = audioRef.child(filename)
    
    storageRef.child("moe.m4a").getData(maxSize: 1*1024*1024) { (data, error) in
      if let data = data {
        let uploadTask = testAudioRef.putData(data, metadata: nil) { (metadata, error) in
          guard let metadata = metadata else {
            print("error uploading")
            return
          }
          
          print("metadata: \(metadata.description)")
          
          testAudioRef.downloadURL { (url, error) in
            guard let downloadURL = url else {
              print("no downloadURL...")
              return
            }
            print(downloadURL.absoluteString)
            
            testAudioRef.getData(maxSize: 1*1024*1024) { (data, error) in
              guard let data = data else {
                print("no data downloaded from \(downloadURL.absoluteString)")
                return
              }
              print("data downloaded!")
              print(data.description)
            }
          }
        }
        
        uploadTask.resume()
      }
      else {
        print("data is nil lol")
      }
    }
  }
}
