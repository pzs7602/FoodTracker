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
import Photos

protocol MyLocationDelegate {
    func getCurrentLocation() -> CLLocation?
}

class FoodViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITextFieldDelegate,WeiboLoginDelegate {
    
    var food: Food?
    var delegate:MyLocationDelegate?
    var previousScale:CGFloat=1.0
    var beginX,beginY:CGFloat?
    var playerController:AVPlayerViewController?
    var accessToken:String?
    @IBOutlet weak var saveBtn: UIBarButtonItem!
    @IBOutlet weak var photoImage: UIImageView!
    
    @IBOutlet weak var foodNameText: UITextField!
    @IBOutlet weak var phoneText: UITextField!
    @IBOutlet weak var restaurantText: UITextField!
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
    @IBAction func moveImage(_ recognizer:UIPanGestureRecognizer){
        print("respond to UIPanGestureRecognizer")
        // state 为 Changed 时，在 self.view 的父视图坐标内的新位置
        var newCenter:CGPoint = recognizer.translation(in: self.view)
        //        println("state=\(returnStateString(recognizer.state))")
        // Pan 手势开始
        if recognizer.state == UIGestureRecognizer.State.began{
            // beginX,beginY 为Pan 手势开始时图像中心的坐标
            self.beginX = self.photoImage!.center.x
            self.beginY = self.photoImage!.center.y
        }
        // 图像新的中心位置
        newCenter = CGPoint(x: self.beginX! + newCenter.x, y: self.beginY! + newCenter.y)
        
        self.photoImage!.center=newCenter
        
    }
    @IBAction func pinchImage(_ recognizer: UIPinchGestureRecognizer) {
        guard self.photoImage != nil else{
            print("image nil")
            return
        }
        if recognizer.state == UIGestureRecognizer.State.ended {
            // 如果Pinch 手势结束，重置 previousScale 为 1.0
            self.previousScale = 1
            print("Pinch Ended")
            return
        }
        print("scale=\([recognizer.scale])")
        let newScale:CGFloat = recognizer.scale-self.previousScale+1.0
        
        let currentTransformation:CGAffineTransform = self.photoImage!.transform
        // CGAffineTransformScale(currentTransformation, 1, 1) 变换保持原大小
        let newTransform:CGAffineTransform = currentTransformation.scaledBy(x: newScale, y: newScale)
        // perform the new transform
        self.photoImage!.transform = newTransform
        
        self.previousScale = recognizer.scale
    }
    // 拍摄视频／图像或从照片库选取视频／图像后均调用本方法
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        let name = foodNameText.text ?? ""
        self.food!.name = name
        if picker.sourceType == .camera{
            food!.location = self.delegate?.getCurrentLocation()
        }
        else{
            food!.location = nil
            let assetURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.referenceURL)] as? URL
            let assets = PHAsset.fetchAssets(withALAssetURLs: [assetURL!], options: nil)
            let asset = assets.firstObject! as PHAsset
            if let loc = asset.location{
                print("loc=\(loc.coordinate.longitude)")
                food!.location = loc
            }
        }
        // clear the video resource attached to food before
        // taken video saved in app's Documents directory
        if let file = self.food?.videoFileName{
            do{
                let filePath = (self.applicationDocumentsDirectory.path! as NSString).appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: filePath)
            }
            catch let error as Error?{
                print("error removing file:\(error!.localizedDescription)")
            }
        }
        // if user take/pick a photo
        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage{
            photoImage.image = image
            self.food?.photo = image
            food!.videoFileName = nil
        }
        // else if user take/pick a video
        else{
            // if user take/pick a video, the pathURL is in tmp dir of the App's sandbox, so we have to save its data
            let tempURL = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.mediaURL)] as? URL
            let dateFormat = DateFormatter()
            print("temp video=\(String(describing: tempURL?.lastPathComponent))")
            
            dateFormat.dateFormat = "yyyyMMdd-HHmmss"
            // video file name: videoyyyyMMdd-HHmmss.mov
            // 注意：应用程序文档目录在每次运行时都不一致，故此处只保存文件名部分
            food!.videoFileName = "video" + dateFormat.string(from: NSDate() as Date) + ".MOV"
            let filePath = (self.applicationDocumentsDirectory.path! as NSString).appendingPathComponent((food?.videoFileName)!)
            do{
                try FileManager.default.moveItem(atPath:tempURL!.path,toPath:filePath)
            }
            catch let error as Error?{
                print("error moving file:\(error!.localizedDescription)")
            }
            photoImage.image = self.getImageFrom(videoURL: URL(fileURLWithPath: filePath),atSeconds: 1.0) ?? UIImage(named: "defaultImg")
            self.food?.photo = photoImage.image
            print("video URL=\(filePath)")
        }
        
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // remove video file save before
        if let file = food?.videoFileName{
            do{
                let filePath = (self.applicationDocumentsDirectory.path! as NSString).appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: filePath)
            }
            catch let error as Error?{
                print("error removing file:\(error!.localizedDescription)")
            }
        }
        // Dismiss the picker.
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.foodNameText.delegate = self
        self.phoneText.delegate = self
        self.restaurantText.delegate = self
        if let food = food {
            navigationItem.title = food.name
            foodNameText.text   = food.name
            photoImage.image = food.photo
            phoneText.text = food.phone
            restaurantText.text = food.restaurant
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
 
    }
    @IBAction func exitToFoodViewCancel(_ segue: UIStoryboardSegue){

    }
    @IBAction func takePhotoAction(_ sender: AnyObject) {
        // UIImagePickerController is a view controller that lets a user pick media from their photo library.
        let imagePickerController = UIImagePickerController()
        let availableSourceTypes = UIImagePickerController.availableMediaTypes(for: UIImagePickerController.SourceType.camera)
        
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        // if segue trigered by the save button
        if sender is UIBarButtonItem && saveBtn === sender as! UIBarButtonItem{
            food?.name = self.foodNameText.text!
            food?.phone = self.phoneText.text!
            food?.restaurant = self.restaurantText.text!
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
    
    @IBAction func noAction(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("提示", comment: "Alert"), message:  NSLocalizedString("本功能只在 iOS10 下有效", comment: "Please input a food name") , preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("确定", comment: "OK") , style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func noAction2(_ sender: Any) {
        noAction(self);
    }
    
    @IBAction func noActoion3(_ sender: Any) {
        noAction(self)
    }
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        // ensure user has input a foond name
        // judge the sender is UIbarButtonItem first
        if sender is UIBarButtonItem && saveBtn === sender as! UIBarButtonItem{
            if self.foodNameText.text == nil || self.foodNameText.text == ""{
                let alert = UIAlertController(title: NSLocalizedString("Alert", comment: "Alert"), message:  NSLocalizedString("Please input a food name", comment: "Please input a food name") , preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK") , style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
                return false
            }
            // ensure the telephone number is correct
            guard URL(string: "tel://" + self.phoneText.text!) != nil else{
                let alert = UIAlertController(title: NSLocalizedString("Alert", comment: "Alert"), message:  NSLocalizedString("Telephone number is incorrect", comment: "Telephone number is incorrect") , preferredStyle: .alert)
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
        catch let error as Error?{
            print("error=\(error!.localizedDescription)")
        }
        let image:UIImage? = UIImage(cgImage: cgImage!)
        return image
    }


    @IBAction func shareAction(_ sender: Any) {
        self.presentLoginViewController(sender)
    }
    @IBAction func presentLoginViewController(_ sender: Any) {
        // accessToken is nil, let user login
        if self.accessToken == nil{
            let nav = self.storyboard?.instantiateViewController(withIdentifier: "webNav") as! UINavigationController
            let vc = nav.viewControllers[0] as! WeiboViewController
            vc.delegate = self
            self.present(nav, animated: true, completion: nil)
        }
        else{
            // use AFNetworking farmework
//            let params = ["status":"来自 美食迹 的分享：" + food!.name,"lat":food!.location!.coordinate.latitude,"long":food!.location!.coordinate.longitude] as [String : Any]
//            Utility.shared.postStatus(accessToken: self.accessToken!, params: params, image: food!.photo!, completion: {(result:[String : Any]?, isSuccess:Bool) -> () in
//                if isSuccess {
//                    print("OK")
//                }
//                else{
//                    print("upload error:\(result)")
//                }
//            })
            let params = ["status":"来自 美食迹 的分享：" + food!.name,"access_token":self.accessToken!,"lat":food!.location!.coordinate.latitude,"long":food!.location!.coordinate.longitude] as [String : Any]
            Utility.shared.uploadImage(url: "https://upload.api.weibo.com/2/statuses/upload.json", parameters: params, filename: "pic", image: food!.photo!,
                success: {(response:NSDictionary) -> Void in
                    print("response:\(response)")
                },
                errord: {(error:NSError) -> Void in
                    print("error=\(error.description)")
                }
            )
        }
    }
    func didLogin(access_token: String?) {
        self.accessToken = access_token
        self.dismiss(animated: true, completion: nil)
        guard access_token != nil else{
            print("user cancel login")
            return
        }
        let params = ["status":"来自 美食迹 的分享：" + food!.name,"lat":food!.location!.coordinate.latitude,"long":food!.location!.coordinate.longitude] as [String : Any]
        Utility.shared.postStatus(accessToken: access_token!, params: params, image: food!.photo!, completion: {(result:[String : Any]?, isSuccess:Bool) -> () in
            if isSuccess {
                print("OK")
            }
            else{
                print("upload error:\(result)")
            }
        })
        
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

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
