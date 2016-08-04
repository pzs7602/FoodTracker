//
//  Food.swift
//  FoodTracker
//
//  Created by PZS on 16/7/18.
//  Copyright © 2016年 SCNU. All rights reserved.
//

import UIKit
import CoreLocation
// 当Food 有视频材料时，photo 属性为该视频第1秒缩略图
// 当Food 没有视频而有拍摄的图像时，photo 为该图像，但此时 videoFileName 属性为 nil，以此区别
class Food: NSObject,NSCoding {
    
    var name: String
    var photo: UIImage?
    var location:CLLocation?
    var videoFileName: String?
    
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("foods")
    override init(){
        self.name = ""
        
    }
    init?(name: String, photo: UIImage?,location:CLLocation?,videoFileName:String?) {
        
        self.name = name
        self.photo = photo
        self.location = location
        self.videoFileName = videoFileName
        super.init()
        
        if name.isEmpty  {
            return nil
        }
    }
    // for object persistence
    required convenience init?(coder aDecoder: NSCoder) {
        let name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as! String
        let photo = aDecoder.decodeObject(forKey: PropertyKey.photoKey) as? UIImage
        let location = aDecoder.decodeObject(forKey:PropertyKey.location) as? CLLocation
        let videoFileName = aDecoder.decodeObject(forKey:PropertyKey.videoFileName) as? String
        self.init(name: name, photo: photo,location: location,videoFileName:videoFileName)
    }
    
    // for object persistence
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(photo, forKey: PropertyKey.photoKey)
        aCoder.encode(location, forKey: PropertyKey.location)
        aCoder.encode(videoFileName,forKey: PropertyKey.videoFileName)
    }
    
}

struct PropertyKey {
    static let nameKey = "name"
    static let photoKey = "photo"
    static let location = "location"
    static let videoFileName = "videoURL"
}
