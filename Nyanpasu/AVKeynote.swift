////
////  AVExample.swift
////  Nyanpasu
////
////  Created by Yuske Fukuyama on 2018/07/04.
////  Copyright © 2018 Yuske Fukuyama. All rights reserved.
////
//
//import Foundation
//import UIKit
//import AVFoundation
//import WatchKit
//
//// Simple Playback and Recording
//// AVFoundation
//
//// AVAudioPlayer Example - Productivity App
//class ViewController: UIViewController {
//  var successSoundPlayer: AVAudioPlayer!
//  let successSoundURL = Bundle.main.urlForResource("success", withExtension: "caf")
//  override func viewDidLoad() {
//    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
//
//    do { // setup AVAudioSession if necessary (Ambient); setup other members
//      successSoundPlayer = try AVAudioPlayer.init(contentsOf: successSoundURL!)
//      successSoundPlayer.prepareToPlay
//    }
//
//    // AVAudioRecorder Example
//    do { // setup AVAudioSession (Record/PlayAndRecord); user permission; input selection
//      let formatSettings: [String: Any] = [AVSampleRateKey : 441000.0,
//                                           AVNumberOfChannelsKey : 1,
//                                           AVFormatIDKey : Int(kAudioFormatMPEG4AAC),
//                                           AVEncoderBitRateKey : 192000,
//                                           AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue]
//
//      let recorder = try AVAudioRecorder.init(url: recordSoundURL, settings: formatSettings)
//      recorder.prepareToRecord()
//    }
//
//    catch {
//      // handle error
//    }
//
//    @IBAction func saveDocument() {
//      // do some other work if successful, play success sound!
//      successSoundPlayer.play()
//    }
//
//    // AVAudioRecorder Example
//    @IBAction func toggleRecorder() {
//      if recorder.isRecording {
//        recorder.stop()
//      }
//      else {
//        recorder.record()
//        // provide feedback using meters
//      }
//    }
//  }
//}
//
//// Advanced Playback and Recording
//
//class GameController: WKInterfaceController {
//  // engine and nodes
//  var audioEngine = AVAudioEngine()
//  let explosionPlayer = AVAudioPlayerNode()
//  let launchPlayer = AVAudioPlayerNode()
//
//  // URLS to our audio assets
//  let explosionAudioURL = URL.init(fileURLWithPath: "/path/to/explosion.caf")
//  let launchAudioURL = URL.init(fileURLWithPath: "/path/to/launch.caf")
//
//  // buffers for Playback (providing data to engine)
//  var explosionBuffer: AVAudioPCMBuffer?
//  var launchBuffer: AVAudioPCMBuffer?
//
//  func somewhere() {
//    audioEngine.attach(explosionPlayer)
//    audioEngine.attach(launchPlayer)
//
//    do {
//      // for each of my url assets
//      let explosionAudioFile = try AVAudioFile.init(forReading: explosionAudioURL)
//      let launchAudioFile = try AVAudioFile.init(forReading: launchAudioURL)
//
//      explosionBuffer = AVAudioPCMBuffer(pcmFormat: explosionAudioFile.processingFormat, frameCapacity: AVAudioFrameCount(explosionAudioFile.length))
//      try explosionAudioFile.read(into: explosionBuffer!)
//
//      // make connections
//      audioEngine.connect(explosionPlayer, to: audioEngine.mainMixerNode, format: explosionAudioFile.processingFormat)
//      audioEngine.connect(launchPlayer, to: audioEngine.mainMixerNode, format: launchAudioFile.processingFormat)
//    }
//    catch { /* handle error  */ }
//  }
//
//  func startGame() {
//    do {
//      try audioEngine.start()
//      explosionPlayer.play()
//      launchPlayer.play()
//    }
//    catch { /* handle error  */ }
//
//    // create an astroid and launch
//    launchPlayer.scheduleBuffer(launchBuffer!, completionHandler: nil)
//    // wait to launch again
//
//    // asteroid is destroyed
//    explosionPlayer.scheduleBuffer(explosionBugger!, completionHandler: nil)
//    // clean up scene and destroy the node
//  }
//}
//
////Performance
////in audio this means Latency (time it takes for a signal to pass through a system)
////
////Latency = delay
////input signal -> output signal
////
////when your code for processing doesn't meet the deadline(like cars, a constant input or output) it will junk, or popcorn
