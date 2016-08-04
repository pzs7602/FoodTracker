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

class SpeechViewController: UIViewController,AVAudioRecorderDelegate {

    @IBOutlet weak var okButton: UIBarButtonItem!
    @IBOutlet weak var startStopButton: UIBarButtonItem!
    
    @IBOutlet weak var speechText: UITextView!
    var audioUrl:URL?
    var recorder: AVAudioRecorder?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.speechText.text = ""
    }

    @IBAction func startStopAction(_ sender: AnyObject) {
        let item = sender as! UIBarButtonItem
        if item.title == "Start"{
            item.title = "Stop"
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
        else{
            item.title = "Start"
            self.recorder?.stop()
            SFSpeechRecognizer.requestAuthorization { authStatus in
                if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
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
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.gdou.RadioPlayer" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
