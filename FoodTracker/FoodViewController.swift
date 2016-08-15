//
//  FoodViewController.swift
//  FoodTracker
//
//  Created by PZS on 16/7/18.
//  Copyright © 2016年 SCNU. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices
import AVKit
import MediaPlayer
import Speech

protocol MyLocationDelegate {
    func getCurrentLocation() -> CLLocation?
}

class FoodViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextFieldDelegate {
    
    var food: Food?
    var delegate:MyLocationDelegate?
    var playerController:AVPlayerViewController?
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    
    @IBOutlet weak var foodNameText: UITextField!
    // invoked when user tap the image
    @IBAction func pickImage(_ sender: UITapGestureRecognizer) {
        if let _ = self.food?.videoFileName{
//            for file in try! FileManager.default.contentsOfDirectory(atPath: self.applicationDocumentsDirectory.path!){
//                print("file=\(file)")
//            }
            self.performSegue(withIdentifier: "videoplay", sender: self)
        }
        // food has no video/photo location
        else if let _ = food?.location{
            self.performSegue(withIdentifier: "showmap", sender: self)
        }
    }
    
    @IBOutlet weak var photoImage: UIImageView!
    // 拍摄视频／图像或从照片库选取视频／图像后均调用本方法
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let name = foodNameText.text ?? ""
        self.food!.name = name
        if picker.sourceType == .camera{
            food!.location = self.delegate?.getCurrentLocation()
        }
        else{
            food!.location = nil
        }
        // clear the video resource attached to food before
        // taken video saved in app's Documents directory
        if let file = self.food?.videoFileName{
            do{
                let filePath = (self.applicationDocumentsDirectory.path! as NSString).appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: filePath)
            }
            catch let error as NSError?{
                print("error removing file:\(error?.description)")
            }
        }
        // if user take/pick a photo
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage{
            photoImage.image = image
            self.food?.photo = image
            food!.videoFileName = nil
        }
        // else if user take/pick a video
        else{
            // if user take/pick a video, the pathURL is in tmp dir of the App's sandbox, so we have to save its data
            let tempURL = info[UIImagePickerControllerMediaURL] as? URL
            let dateFormat = DateFormatter()
            print("temp video=\(tempURL?.lastPathComponent)")
            
            dateFormat.dateFormat = "yyyyMMdd-HHmmss"
            // video file name: videoyyyyMMdd-HHmmss.mov
            // 注意：应用程序文档目录在每次运行时都不一致，故此处只保存文件名部分
            food!.videoFileName = "video" + dateFormat.string(from: NSDate() as Date) + ".MOV"
            let filePath = (self.applicationDocumentsDirectory.path! as NSString).appendingPathComponent((food?.videoFileName)!)
            do{
                try FileManager.default.moveItem(atPath:tempURL!.path,toPath:filePath)
            }
            catch let error as NSError?{
                print("error moving file:\(error?.description)")
            }
            photoImage.image = self.getImageFrom(videoURL: URL(fileURLWithPath: filePath),atSeconds: 1.0) ?? UIImage(named: "defaultImg")
            self.food?.photo = photoImage.image
            print("video URL=\(filePath)")
        }
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.foodNameText.delegate = self
        if let food = food {
            navigationItem.title = food.name
            foodNameText.text   = food.name
            photoImage.image = food.photo
        }
        else{
            // if food is nil, this is add operation
            self.food = Food()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func cancelPressed(_ sender: AnyObject) {
        
        let isAddNew = self.presentingViewController is UINavigationController
        // if is AddNew, dismiss the modal view
        if isAddNew {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController!.popViewController(animated: true)
        }

    }
    
    @IBAction func exitToFoodView(_ segue: UIStoryboardSegue){
        let vc = segue.source as! SpeechViewController
        self.foodNameText.text = vc.speechText.text
        if vc.capture != nil && vc.capture?.isRunning == true{
            vc.capture?.stopRunning()
            vc.capture = nil
            vc.speechRequest?.endAudio()
        }        
    }
    @IBAction func takePhotoAction(_ sender: AnyObject) {
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        let availableSourceTypes = UIImagePickerController.availableMediaTypes(for: UIImagePickerControllerSourceType.camera)
        
        // take a video.
        imagePickerController.sourceType = .camera
        imagePickerController.cameraDevice = .rear
        // video in mov format
//        imagePickerController.mediaTypes = [String(kUTTypeMovie),String(kUTTypeImage)]
        // 可使界面有其它资源选项：照片、视频...
        imagePickerController.mediaTypes = availableSourceTypes!
        imagePickerController.videoQuality = .typeIFrame1280x720
        imagePickerController.cameraCaptureMode = .video
        imagePickerController.videoMaximumDuration = 60
        
        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    @IBAction func pickPhotoAction(_ sender: AnyObject) {
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        
        // Only allow photos to be picked, not taken.
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [String(kUTTypeMovie),String(kUTTypeImage)]

        // Make sure ViewController is notified when the user picks an image.
        imagePickerController.delegate = self
        
        present(imagePickerController, animated: true, completion: nil)
        
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        // if segue trigered by the save button
        if saveBtn === sender {
            food?.name = self.foodNameText.text!
            // location,photo,videoFileName already set
        }
        // else the segue trigered by tap the image
        else if segue.identifier == "showmap"{
            let vc = (segue.destination as! UINavigationController).topViewController as! MapViewController
            vc.location = food!.location
        }
        else if segue.identifier == "videoplay"{
            let vc = segue.destination as! AVPlayerViewController
            let filePath = (self.applicationDocumentsDirectory.path! as NSString).appendingPathComponent((food?.videoFileName)!)
            print("play:\(filePath)")
            vc.player = AVPlayer(url: URL(fileURLWithPath: filePath))
        }
    }
    // 如果用户未输入食物名称，阻止跳转
    override func shouldPerformSegue(withIdentifier identifier: String, sender: AnyObject?) -> Bool {
        // ensure user has input a foond name
        if saveBtn === sender{
            if self.foodNameText.text == nil || self.foodNameText.text == ""{
                let alert = UIAlertController(title: NSLocalizedString("Alert", comment: "Alert"), message:  NSLocalizedString("Please input a food name", comment: "Please input a food name") , preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK") , style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return false
            }
        }
        return true
    }
    // get a thumbnail image from a video file
    func getImageFrom(videoURL:URL,atSeconds:Double) ->UIImage?{
        let asset = AVURLAsset(url: videoURL)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        let time = CMTime(seconds: atSeconds, preferredTimescale: 1)
        var actualTime: CMTime = CMTime(seconds: 1.0, preferredTimescale: 1)
        var cgImage:CGImage?
        do{
            cgImage = try gen.copyCGImage(at: time, actualTime: &actualTime)
        }
        catch let error as NSError?{
            print("error=\(error?.description)")
        }
        let image:UIImage? = UIImage(cgImage: cgImage!)
        return image
    }

    @IBAction func speechRecord(_ sender: AnyObject) {

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.gdou.RadioPlayer" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
}
