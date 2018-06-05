//
//  SpeechViewController.swift
//  FoodTracker
//
//  Created by pan zhansheng on 16/8/3.
//  Copyright © 2016年 idup. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer
import Speech

class SpeechViewController: UIViewController,AVAudioRecorderDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,SFSpeechRecognitionTaskDelegate {

    @IBOutlet weak var okButton: UIBarButtonItem!
    @IBOutlet weak var startStopButton: UIBarButtonItem!
    
    @IBOutlet weak var speechText: UITextView!
    var audioUrl:URL?
    var recorder: AVAudioRecorder?
    var capture: AVCaptureSession?
    var speechRequest:SFSpeechAudioBufferRecognitionRequest?
    var speechRecognizer:SFSpeechRecognizer?
    var sender: Int = 0   // 标志是哪个字段的识别文字：1 name , 2 phone, 3 restaurant
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.speechText.text = ""
    }
    // this recognition action is for recorded audio URL recognition
    @IBAction func startStopAction(_ sender: AnyObject) {
        let item = sender as! UIBarButtonItem
        // start to record audio
        if item.title == NSLocalizedString("Start", comment: "Start"){
            item.title = NSLocalizedString("Stop", comment: "Stop")
            let aacAudioSettings = [AVFormatIDKey:NSNumber(value: kAudioFormatMPEG4AAC),
                                    AVSampleRateKey:NSNumber(value: 44100.0),
                                    AVNumberOfChannelsKey:2,
                                    ]
            self.audioUrl = self.applicationDocumentsDirectory.appendingPathComponent("sound.aac")
            do{
                if FileManager.default.fileExists(atPath: (audioUrl?.path)!){
                    try FileManager.default.removeItem(at: audioUrl!)
                }
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, with: AVAudioSessionCategoryOptions.allowBluetooth)
                
                try AVAudioSession.sharedInstance().setActive(true)
                self.recorder = try AVAudioRecorder(url: audioUrl!, settings: aacAudioSettings)
                AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] (allowed: Bool) -> Void in
                    DispatchQueue.main.async{
                        if allowed {
                            self.recorder?.delegate = self
                            self.recorder?.prepareToRecord()
                            self.recorder?.record(forDuration: 100)
                        } else {
                            // failed to record!
                            
                        }
                    }
                }
            }catch let err as NSError?{
                print("err=\(err!.description)")
                
            }
        }
        // audio recorded, start to speech recognize
        else{
            item.title = NSLocalizedString("Start", comment: "Start")
            self.recorder?.stop()
            SFSpeechRecognizer.requestAuthorization { authStatus in
                if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
                    // default language is OS's language
                    let recognizer = SFSpeechRecognizer()
                    let request = SFSpeechURLRecognitionRequest(url: self.audioUrl!)
                    recognizer?.recognitionTask(with: request){ (result, error) in
                        if let error = error {
                            print("There was an error: \(error)")
                        } else {
                            DispatchQueue.main.async {
                                self.speechText.text = result?.bestTranscription.formattedString
                                
                            }
                        }
                    }
                }
            }

        }
    }
    // this is for real time audio recognition
    @IBAction func startStopAction2(_ sender: AnyObject) {
        let item = sender as! UIBarButtonItem
        if item.title == NSLocalizedString("Start", comment: "Start"){
            item.title = NSLocalizedString("Stop", comment: "Stop")
            SFSpeechRecognizer.requestAuthorization { authStatus in
                if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
                    self.speechRecognizer = SFSpeechRecognizer()
                    self.speechRequest = SFSpeechAudioBufferRecognitionRequest()
                    self.speechRecognizer?.recognitionTask(with: self.speechRequest!, delegate: self)
                    DispatchQueue.main.async {
                        self.startCapture()
                    }

                }
            }
        }
        else{
            item.title = NSLocalizedString("Start", comment: "Start")
            self.endCapture()
        }
    }
    
    func startCapture()
    {
        self.capture = AVCaptureSession()
        let audioDev = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        guard audioDev != nil else{
            print("could not create audio capture device")
            return
        }
        let audioIn = try! AVCaptureDeviceInput(device: audioDev)
        if self.capture?.canAddInput(audioIn) == false{
            print("")
            return
        }
        self.capture?.addInput(audioIn)
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        if self.capture?.canAddOutput(audioOutput) == false{
            print("")
            return
        }
        self.capture?.addOutput(audioOutput)
        audioOutput.connection(withMediaType: AVMediaTypeAudio)
        self.capture?.startRunning()
    }
    func endCapture(){
        if self.capture != nil && self.capture?.isRunning == true{
            self.capture?.stopRunning()
            self.capture = nil
            self.speechRequest?.endAudio()
        }
    }
    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {
        print("speechRecognitionDidDetectSpeech")
    }
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        print("didHypothesizeTranscription")
        print("\(transcription.formattedString)")
        DispatchQueue.main.async {
            self.speechText.text = transcription.formattedString
        }
    }
    // when endAudio executed
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        print("didFinishRecognition")
    }
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        self.speechRequest?.appendAudioSampleBuffer(sampleBuffer)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.gdou.RadioPlayer" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        
    }
    

}
