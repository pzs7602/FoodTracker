//
//  Utility.swift
//  weibo
//
//  Created by pan zhansheng on 2016/10/29.
//  Copyright © 2016年 pan zhansheng. All rights reserved.
//

import UIKit
import MobileCoreServices
import AFNetworking

enum WBHTTPMethod {
    case GET
    case POST
}
/// 用户需要登录通知
let WBUserShouldLoginNotification = "WBUserShouldLoginNotification"

extension Data {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
class Utility {
    // singleton
    static let shared = Utility()
    let manager = AFHTTPSessionManager()
    /// Description
    ///
    /// - Parameters:
    ///   - accessToken: access token
    ///   - urlString: 微博接口地址
    ///   - parameter: 参数
    ///   - completionHandler: 结果回调
    func tokenPostRequest(accessToken:String,urlString:String,parameter:String,completionHandler:@escaping (Data?, URLResponse?, Error?) -> Void)
    {
        var parameter = parameter + "&access_token=\(accessToken)"
        parameter = parameter.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        let url:URL = URL(string:urlString)!
        var urlRequest:URLRequest = URLRequest(url:url)
        urlRequest.httpMethod="Post"
        
        urlRequest.httpBody = parameter.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        let dataTask:URLSessionDataTask = URLSession.shared.dataTask(with: urlRequest){ (data:Data?, response:URLResponse?, error:Error?) -> Void in
//            let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
//            print("data=\(dataString!)")
            completionHandler(data,response,error)
        }
        dataTask.resume()
    }
    func tokenGetRequest(accessToken:String,urlString:String,parameter:String,completionHandler:@escaping (Data?, Error?) -> Void){
        DispatchQueue.global().async{
            let url = URL(string: urlString + "?access_token=\(accessToken)&" + parameter)
            var data:Data?
            do{
                data = try Data(contentsOf: url!)
                completionHandler(data,nil)
            }
            catch let error as NSError{
                completionHandler(data,error)
            }
        }
    }

    func tokenFormUploadRequest(accessToken:String,urlString:String,parameter:[String:String]?,paths:[String],completionHandler:@escaping (Data?, URLResponse?,Error?) -> Void)
    {
        let url:URL = URL(string:urlString)!
        var urlRequest:URLRequest = URLRequest(url:url)
        let boundary = generateBoundaryString()
        urlRequest.httpMethod="Post"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
//        urlRequest.httpBody = parameter.data(using: String.Encoding.utf8, allowLossyConversion: false)
        do{
            urlRequest.httpBody = try createBody(with: parameter, filePathKey: "pic", paths: paths, boundary: boundary)
            let dataTask:URLSessionDataTask = URLSession.shared.dataTask(with: urlRequest){ (data:Data?, response:URLResponse?, error:Error?) -> Void in
                let dataString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                print("data=\(dataString!)")
                completionHandler(data,response,error)
            }
            dataTask.resume()
        }
        catch let error as NSError{
            print("form upload error=\(error.description)")
        }
    }
    
    func createBody(with parameters: [String: String]?, filePathKey: String, paths: [String], boundary: String) throws -> Data {
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        
        for path in paths {
            let url = URL(fileURLWithPath: path)
            let filename = url.lastPathComponent
            let data = try Data(contentsOf: url)
            let mimetype = mimeType(for: path)
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
        
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    
    func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
    /// Determine mime type on the basis of extension of a file.
    ///
    /// This requires MobileCoreServices framework.
    ///
    /// - parameter path:         The path of the file for which we are going to determine the mime type.
    ///
    /// - returns:                Returns the mime type if successful. Returns application/octet-stream if unable to determine mime type.
    
    func mimeType(for path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }

    /// 发布微博
    ///
    /// - parameter text:       要发布的文本
    /// - parameter image:      要上传的图像，为 nil 时，发布纯文本微博
    /// - parameter completion: 完成回调
    func postStatus(accessToken:String,params:[String:Any]?, image: UIImage?, completion: @escaping (_ result: [String: Any]?, _ isSuccess: Bool)->()) -> () {
        
        // 1. url
        let urlString: String
        
        // 根据是否有图像，选择不同的接口地址
        if image == nil {
            urlString = "https://api.weibo.com/2/statuses/update.json"
        } else {
            urlString = "https://upload.api.weibo.com/2/statuses/upload.json"
        }
        
        // 2. 参数字典
        
        // 3. 如果图像不为空，需要设置 name 和 data
        var name: String?
        var data: Data?
        
        if image != nil {
            name = "pic"
            data = image!.jpegData(compressionQuality: 1.0)
        }
        // image size is larger than 5M, so compressed it
        if (data! as NSData).length > 1024*1024*5{
            data = image!.jpegData(compressionQuality: 0.5)
        }
        // 4. 发起网络请求
        tokenRequest(accessToken: accessToken,method: .POST, URLString: urlString, parameters: params as [String : Any]?, name: name, data: data) { (json, isSuccess) in
            completion(json as? [String: Any], isSuccess)
        }
    }

    /// 专门负责拼接 token 的网络请求方法
    ///
    /// - parameter method:     GET / POST
    /// - parameter URLString:  URLString
    /// - parameter parameters: 参数字典
    /// - parameter name:       上传文件使用的字段名，默认为 nil，不上传文件
    /// - parameter data:       上传文件的二进制数据，默认为 nil，不上传文件
    /// - parameter completion: 完成回调
    func tokenRequest(accessToken:String,method: WBHTTPMethod = .GET, URLString: String, parameters: [String: Any]?, name: String? = nil, data: Data? = nil, completion: @escaping (_ json: Any?, _ isSuccess: Bool)->()) {
        
        
        // 1> 判断 参数字典是否存在，如果为 nil，应该新建一个字典
        var parameters = parameters
        if parameters == nil {
            // 实例化字典
            parameters = [String: Any]()
        }
        
        // 2> 设置参数字典，代码在此处字典一定有值
        parameters!["access_token"] = accessToken
        
        // 3> 判断 name 和 data
        if let name = name, let data = data {
            // 上传文件
            upload(URLString: URLString, parameters: parameters, name: name, data: data, completion: completion)
        } else {
            
            // 调用 request 发起真正的网络请求方法
            // request(URLString: URLString, parameters: parameters, completion: completion)
            request(method: method, URLString: URLString, parameters: parameters, completion: completion)
        }
    }
    
    // MARK: - 封装 AFN 方法
    /// 上传文件必须是 POST 方法，GET 只能获取数据
    /// 封装 AFN 的上传文件方法
    ///
    /// - parameter URLString:  URLString
    /// - parameter parameters: 参数字典
    /// - parameter name:       接收上传数据的服务器字段(name - 要咨询公司的后台) `pic`
    /// - parameter data:       要上传的二进制数据
    /// - parameter completion: 完成回调
    func upload(URLString: String, parameters: [String: Any]?, name: String, data: Data, completion: @escaping (_ json: Any?, _ isSuccess: Bool)->()) {
        
        self.manager.post(URLString, parameters: parameters, constructingBodyWith: { (formData) in
            
            // 创建 formData
            /**
             1. data: 要上传的二进制数据
             2. name: 服务器接收数据的字段名
             3. fileName: 保存在服务器的文件名，大多数服务器，现在可以乱写
             很多服务器，上传图片完成后，会生成缩略图，中图，大图...
             4. mimeType: 告诉服务器上传文件的类型，如果不想告诉，可以使用 application/octet-stream
             image/png image/jpg image/gif
             */
            formData.appendPart(withFileData: data, name: name, fileName: "xxx", mimeType: "application/octet-stream")
            
        }, progress: nil, success: { (_, json) in
            
            completion(json, true)
        }) { (task, error) in
            
            if (task?.response as? HTTPURLResponse)?.statusCode == 403 {
                print("Token 过期了")
                
                // 发送通知，提示用户再次登录(本方法不知道被谁调用，谁接收到通知，谁处理！)
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: WBUserShouldLoginNotification),
                    object: "bad token")
            }
            
            print("网络请求错误 \(error)")
            
            completion(nil, false)
        }
    }
    
    /// 封装 AFN 的 GET / POST 请求
    ///
    /// - parameter method:     GET / POST
    /// - parameter URLString:  URLString
    /// - parameter parameters: 参数字典
    /// - parameter completion: 完成回调[json(字典／数组), 是否成功]
    func request(method: WBHTTPMethod = .GET, URLString: String, parameters: [String: Any]?, completion: @escaping (_ json: Any?, _ isSuccess: Bool)->()) {
        
        // 成功回调
        let success = { (task: URLSessionDataTask, json: Any?)->() in
            
            completion(json, true)
        }
        
        // 失败回调
        let failure = { (task: URLSessionDataTask?, error: Error)->() in
            
            // 针对 403 处理用户 token 过期
            // 对于测试用户(应用程序还没有提交给新浪微博审核)每天的刷新量是有限的！
            // 超出上限，token 会被锁定一段时间
            // 解决办法，新建一个应用程序！
            if (task?.response as? HTTPURLResponse)?.statusCode == 403 {
                print("Token 过期了")
                
                // 发送通知，提示用户再次登录(本方法不知道被谁调用，谁接收到通知，谁处理！)
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: WBUserShouldLoginNotification),
                    object: "bad token")
            }
            
            // error 通常比较吓人，例如编号：XXXX，错误原因一堆英文！
            print("网络请求错误 \(error)")
            
            completion(nil, false)
        }
        
        if method == .GET {
            self.manager.get(URLString, parameters: parameters, progress: nil, success: success, failure: failure)
        } else {
            
            self.manager.post(URLString, parameters: parameters, progress: nil, success: success, failure: failure)
        }
    }
    //
    /// we donnt use AFNetworking framework
    ///
    /// - Parameters:
    ///   - url: URL 地址
    ///   - parameters: 参数字典，必须包含 access_token
    ///   - filename: 上传文件名字，对于Weibo，为 pic
    ///   - image: 欲上传的图像数据 UIImage
    ///   - success: 成功时的回调
    ///   - errord: 出错时的回调
    public func uploadImage(url: String,parameters: Dictionary<String,Any>?,filename:String,image:UIImage, success:((NSDictionary) -> Void)!,  errord:@escaping ((NSError) -> Void)) {
        let TWITTERFON_FORM_BOUNDARY:String = "AaB03x"
        let url = NSURL(string: url)!
        let request:NSMutableURLRequest = NSMutableURLRequest(url: url as URL, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let MPboundary:String = "--\(TWITTERFON_FORM_BOUNDARY)"
        let endMPboundary:String = "\(MPboundary)--"
        //convert UIImage to NSData
        var data:NSData = image.jpegData(compressionQuality: 1.0)! as NSData
        // image size larger than 5M, compress it
        if data.length > 1024*1024*5{
            data = image.jpegData(compressionQuality: 0.5)! as NSData
        }
        let body:NSMutableString = NSMutableString();
        // with other params
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendFormat("\(MPboundary)\r\n" as NSString)
                body.appendFormat("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n" as NSString)
                body.appendFormat("\(value)\r\n" as NSString)
            }
        }
        // set upload image, name is the key of image
        body.appendFormat("%@\r\n",MPboundary)
        body.appendFormat("Content-Disposition: form-data; name=\"\(filename)\"; filename=\"myimagefile.jpg\"\r\n" as NSString)
        body.appendFormat("Content-Type: image/jpg\r\n\r\n")
        let end:String = "\r\n\(endMPboundary)"
        print("body=")
        print("\(body)")
        let myRequestData:NSMutableData = NSMutableData();
        myRequestData.append(body.data(using: String.Encoding.utf8.rawValue)!)
        myRequestData.append(data as Data)
        myRequestData.append(end.data(using: String.Encoding.utf8)!)
        let content:String = "multipart/form-data; boundary=\(TWITTERFON_FORM_BOUNDARY)"
        request.setValue(content, forHTTPHeaderField: "Content-Type")
        request.setValue("\(myRequestData.length)", forHTTPHeaderField: "Content-Length")
        request.httpBody = myRequestData as Data
        request.httpMethod = "POST"
        //        var conn:NSURLConnection = NSURLConnection(request: request, delegate: self)!
        let task = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            if error != nil {
                print("error=\(error!.localizedDescription)")
                errord(error as! NSError)
                return
            }
            let responseData = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
            
            if let responseDictionary = responseData as? NSDictionary {
                success(responseDictionary)
            } else {
            }
            
        })
        task.resume()
        
    }

}
