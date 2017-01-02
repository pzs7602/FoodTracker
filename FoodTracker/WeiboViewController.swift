//
//  WeiboViewController.swift
//  FoodTracker
//
//  Created by pan zhansheng on 2016/11/5.
//  Copyright © 2016年 idup. All rights reserved.
//

import UIKit
import JavaScriptCore

let WBAppKey = "53883971"
let WBAppSecret = "d8a6bcba851b148e78145be1551f3d4f"
let WBRedirectURI = "http://www.sina.com"

protocol WeiboLoginDelegate {
    func didLogin(access_token:String?)
}
class WeiboViewController: UIViewController,UIWebViewDelegate {

    var delegate:WeiboLoginDelegate?
    var webView: UIWebView = UIWebView()
    var accessToken:String?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.webView.frame = self.view.frame
        self.view = self.webView
        
        self.webView.delegate = self
        self.weiboLogin()
    }

    // 获取 accessToken 第一步：取得授权码
    func weiboLogin(){
        let urlString = "https://api.weibo.com/oauth2/authorize?client_id=\(WBAppKey)&redirect_uri=\(WBRedirectURI)"
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        self.webView.loadRequest(request)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.delegate?.didLogin(access_token: nil)
    }
    @IBAction func autoFillLoginData(_ sender: Any) {
        let js = "document.getElementById('userId').value = 'pzs7602@yeah.net';" + "document.getElementById('passwd').value = 'pzs26401';"
        self.webView.stringByEvaluatingJavaScript(from: js)
        
    }
    
    // 第二步：获取accessToken
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        // 如果第一步获取授权码调用成功，则会跳转: http://www.sina.com&code=CODE
        // 以下语句保证如果未获得授权码，则显示Web界面（一般是出错信息）
        guard request.url?.absoluteString.hasPrefix("http://www.sina.com") == true && (request.url?.query?.hasPrefix("code=")) == true else{
            return true
        }

        // 如果获得授权码，则继续处理获取access_token，最后方法返回 false，表示不显示获得授权码后的重定向界面
        print("CODE = \(request.url!.query!.components(separatedBy: "=").last!)")
        let authCode = request.url!.query!.components(separatedBy: "=").last!
        DispatchQueue.global().async{
            let urlString = "https://api.weibo.com/oauth2/access_token"
            let url:URL = URL(string:urlString)!
            
            var urlRequest:URLRequest = URLRequest(url:url)
            let params:String = "client_id=\(WBAppKey)&client_secret=\(WBAppSecret)&grant_type=authorization_code&redirect_uri=\(WBRedirectURI)&code=\(authCode)"
            
            urlRequest.httpMethod="Post"
            
            urlRequest.httpBody = params.data(using: String.Encoding.utf8, allowLossyConversion: false)
            
            let dataTask:URLSessionDataTask = URLSession.shared.dataTask(with: urlRequest){ (data:Data?, response:URLResponse?, error:Error?) -> Void in
                if error == nil{
//                    let text:String = NSString(data: data!, encoding:String.Encoding.utf8.rawValue)! as String
                    //                    print("Data = \(text)")
                    do{
                        let dicData:[String:Any]? = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableLeaves) as? [String:Any]
                        if let dicData = dicData{
                            self.accessToken = dicData["access_token"] as? String
                            print("accessToken=\(self.accessToken!)")
                            //
                            DispatchQueue.main.async{
                                self.delegate?.didLogin(access_token: self.accessToken!)
                            }
                        }
                    }
                    catch let error as NSError?{
                        print("error=\(error.debugDescription)")
                    }
                }
                else{
                    print("Error:\(error!.localizedDescription)")
                }
            }
            dataTask.resume()
        }
        return false
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
