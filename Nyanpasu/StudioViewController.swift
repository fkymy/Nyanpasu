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

class StudioViewController: UIViewController {
  
  // MARK: Properties
  let storage = Storage.storage(url: "gs://nyanpasu-7767d.appspot.com")
  var audios: [String] = []

  // Audio
  let session = AVAudioSession.sharedInstance()
  var audioEngine: AVAudioEngine!
  var audioFile : AVAudioFile!
  var audioPlayer : AVAudioPlayerNode!
  var outref: ExtAudioFileRef?
  var audioFilePlayer: AVAudioPlayerNode!
  var mixer: AVAudioMixerNode!
  var filePath: String? = nil
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

  
  // MARK: UIViewController Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    audioEngine = AVAudioEngine()
    audioFilePlayer = AVAudioPlayerNode()
    mixer = AVAudioMixerNode()
    
    tableView.delegate = self
    tableView.dataSource = self
    
    navigationController?.navigationBar.isTranslucent = false
    navigationController?.navigationBar.barStyle = .black
    navigationController?.navigationBar.titleTextAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.white]
    
    setupUI()
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
  }
  
  deinit {
    deactivateAudio()
  }
  
  
  @IBAction func onTouchDown(_ sender: UIButton) {
    print("onTouchDown [start recording]")
    startRecording()
    updateUIForStartRecording()
  }
  
  @IBAction func onTouchUpInside(_ sender: UIButton) {
    print("onTOuchUpInside [complete recording and send message]")
    stopRecording()
    saveRecording()
    updateUIForStopRecording()
  }
  
  @IBAction func onTouchUpOutside(_ sender: UIButton) {
    print("onTouchUpOutside [cancel recording and trash message]")
    stopRecording()
    updateUIForStopRecording()
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
  
  private func saveRecording() {
    let storageRef = storage.reference()
    let studioRef = storageRef.child("studio")
    let filename = "NYANPASU_\(Date().timeIntervalSince1970).caf"

    guard let filePath = filePath else {
      print("no filePath")
      return
    }
    
    let url = URL(fileURLWithPath: filePath)
    let data = try? Data(contentsOf: url)
    if let data = data {
      let uploadTask = studioRef.child(filename).putData(data, metadata: nil) { [weak self] (metadata, error) in
        guard let metadata = metadata else {
          print("error uploading")
          return
        }
        print(metadata.description)
        self?.audios.append(metadata.name!)
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
  
  private func updateUIForStartRecording() {
    recordButtonWidth?.constant = 160 * 1.3
    recordButtonHeight?.constant = 48 * 1.3
  }
  
  private func updateUIForStopRecording() {
    recordButtonWidth?.constant = 160
    recordButtonHeight?.constant = 48
  }
  
  private func setupUI() {
    recordButtonWidth?.constant = 160
    recordButtonHeight?.constant = 48
    recordButton?.isEnabled = true
  }
  
  func activateAudio() {
    do {
      // 1) configure audio session category, options, and mode
      // 2) activate your audio session to enable your custom configuration
      try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
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
  }
}

// MARK: - Storage
extension StudioViewController {
  func brutallyTestStorage() {
    let storageRef = storage.reference()
    let filename = "test-\(Date().timeIntervalSince1970).m4a"
    let audioRef = storageRef.child("audio")
    let testAudioRef = audioRef.child(filename)
    
    storage.reference().child("moe.m4a").getData(maxSize: 1*1024*1024) { (data, error) in
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
