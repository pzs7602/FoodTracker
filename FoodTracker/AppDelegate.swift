//
//  AppDelegate.swift
//  FoodTracker
//
//  Created by PZS on 16/7/18.
//  Copyright © 2016年 SCNU. All rights reserved.
//
/*
FoodTracker 是一个由浅入深的iOS 项目，这是功能最多的最终版本。用户可添加食物并可拍摄图像或视频作为介绍该食物的展示材料，视频文件保存于程序的文档 Documents 目录。文件名 videoyyyyMMdd-HHmmss。
UIScrollView 的使用：
 在 Size Inspector 中，将场景控制器的Simulated Size 改为 Freeform，高度定为 800
 加入UIScrollView 作为根视图的子视图，定 Constraints 的 top/bottom/leading/trailing 为 0
 加入UIView 作为 UIScrollView 的子视图，Label 定为 ContainerView，定义 top/bottom/leading/trailing 为0
 将 ContainerView 的 width 与 ViewController 的根视图 width 相同
 将 ContainerView 的高度定为 650（可酌情修改）。注意：由于滚动区域大小由ContainerView 决定，故除top/bottom/leading/trailing Constraints 外，其宽度、高度必须指定（一般大于屏幕区域）
 在 ContainerView 中加入其它控件
*/
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        NSLog("%@", "applicationDidFinishLaunchingWithOptions")
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NSLog("%@", "applicationWillResignActive")

    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        NSLog("%@", "applicationDidEnterBackground")

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        NSLog("%@", "applicationWillEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("%@", "applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        NSLog("%@", "applicationWillTerminate")
    }


}

