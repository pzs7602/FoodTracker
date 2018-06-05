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
    var phone: String?
    var restaurant: String?
    var comment: String?
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("foods")
    override init(){
        self.name = ""
        self.phone = ""
        self.comment = ""
        self.restaurant = ""
    }
    init?(name: String, photo: UIImage?,location:CLLocation?,videoFileName:String?,phone:String?,restaurant:String?,comment:String = "") {
        
        self.name = name
        self.photo = photo
        self.location = location
        self.phone = phone
        self.comment = comment
        self.restaurant = restaurant
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
        let phone = aDecoder.decodeObject(forKey:PropertyKey.phone) as? String
        let restaurant = aDecoder.decodeObject(forKey:PropertyKey.restaurant) as? String
        self.init(name: name, photo: photo,location: location,videoFileName:videoFileName,phone:phone,restaurant:restaurant)
    }
    
    // for object persistence
    func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: PropertyKey.nameKey)
        aCoder.encode(photo, forKey: PropertyKey.photoKey)
        aCoder.encode(location, forKey: PropertyKey.location)
        aCoder.encode(videoFileName,forKey: PropertyKey.videoFileName)
        aCoder.encode(phone,forKey: PropertyKey.phone)
        aCoder.encode(restaurant,forKey: PropertyKey.restaurant)
        aCoder.encode(comment,forKey: PropertyKey.comment)
    }
    
}

struct PropertyKey {
    static let nameKey = "name"
    static let photoKey = "photo"
    static let location = "location"
    static let videoFileName = "videoURL"
    static let phone = "phone"
    static let restaurant = "restaurant"
    static let comment = "comment"
}
