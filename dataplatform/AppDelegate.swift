//
//  AppDelegate.swift
//  dataplatform
//
//  Created by minzhiqiang on 16/12/30.
//  Copyright © 2016年 minzhiqiang. All rights reserved.
//

import UIKit
import UserNotifications

//蒲公英环境以及app store
let kGtAppId:String = "ZcUhI3ddPs9v2igF83g9K7"
let kGtAppKey:String = "bFKy6sfEGt65oiqGj3CP93"
let kGtAppSecret:String = "9LFYYTuPPs5Onw3wX56oU3"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GeTuiSdkDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    var viewController = ViewController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // [ GTSdk ]：是否允许APP后台运行
        GeTuiSdk.runBackgroundEnable(true);
        // [ GTSdk ]：是否运行电子围栏Lbs功能和是否SDK主动请求用户定位
        GeTuiSdk.lbsLocationEnable(true, andUserVerify: true);
        // [ GTSdk ]：自定义渠道
        GeTuiSdk.setChannelId("GT-Channel");
        // [ GTSdk ]：使用APPID/APPKEY/APPSECRENT启动个推
        GeTuiSdk.start(withAppId: kGtAppId, appKey: kGtAppKey, appSecret: kGtAppSecret, delegate: self);
        // 注册APNs - custom method - 开发者自定义的方法
        self.registerRemoteNotification();
        //增加判断用户是否第一次开启应用
        if UserDefaults.standard.bool(forKey: "everLaunched") == false {
            UserDefaults.standard.set(true, forKey: "everLaunched")
            UserDefaults.standard.set(true, forKey: "firstLaunch")
        }else{
            UserDefaults.standard.set(false, forKey: "firstLaunch")
        }
        
        return true
    }
    
    // MARK: - 用户通知(推送) _自定义方法
    /** 注册用户通知(推送) */
    func registerRemoteNotification() {
        /*
         警告：该方法需要开发者自定义，以下代码根据APP支持的iOS系统不同，代码可以对应修改。
         警告：Xcode8的需要手动开启“TARGETS -> Capabilities -> Push Notifications”
         以下为演示代码，仅供参考，详细说明请参考苹果开发者文档，注意根据实际需要修改，注意测试支持的iOS系统都能获取到DeviceToken。
         */
        let systemVer = (UIDevice.current.systemVersion as NSString).floatValue;
        if systemVer >= 10.0 {
            if #available(iOS 10.0, *) {
                let center:UNUserNotificationCenter = UNUserNotificationCenter.current()
                center.delegate = self;
                center.requestAuthorization(options: [.alert,.badge,.sound], completionHandler: { (granted:Bool, error:Error?) -> Void in
                    if (granted) {
                        print("注册通知成功") //点击允许
                    } else {
                        print("注册通知失败") //点击不允许
                    }
                })
                UIApplication.shared.registerForRemoteNotifications()
            } else {
                let userSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
                UIApplication.shared.registerUserNotificationSettings(userSettings)
                UIApplication.shared.registerForRemoteNotifications()
            };
        } else if systemVer >= 8.0 {
            let userSettings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(userSettings)
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - 远程通知(推送)回调
    /** 远程通知注册成功委托 */
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        var token = deviceToken.description.trimmingCharacters(in: CharacterSet(charactersIn: "<>"));
        token = token.replacingOccurrences(of: " ", with: "")
        // [ GTSdk ]：向个推服务器注册deviceToken
        GeTuiSdk.registerDeviceToken(deviceTokenString);
        NSLog("\n>>>[DeviceToken Success]:%@\n\n",token);
    }
    
    /** 远程通知注册失败委托 */
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("\n>>>[DeviceToken Error]:%@\n\n",error.localizedDescription);
    }
    
    // MARK: - APP运行中接收到通知(推送)处理 - iOS 10 以下
    /** APP已经接收到“远程”通知(推送) - (App运行在后台/App运行在前台) */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        application.applicationIconBadgeNumber = 0;        // 标签
        print("\n>>>[Receive RemoteNotification]:%@\n\n",userInfo);
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // [ GTSdk ]：将收到的APNs信息传给个推统计
        GeTuiSdk.handleRemoteNotification(userInfo);
        print("\n>>>[Receive RemoteNotification]:%@\n\n",userInfo);
        completionHandler(UIBackgroundFetchResult.newData);
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("willPresentNotification: %@",notification.request.content.userInfo);
        completionHandler([.badge,.sound,.alert]);
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("didReceiveNotificationResponse: %@",response.notification.request.content.userInfo);
        // [ GTSdk ]：将收到的APNs信息传给个推统计
        GeTuiSdk.handleRemoteNotification(response.notification.request.content.userInfo);
        completionHandler();
        print(response.notification.request.identifier)
        viewController.showPage(response.notification.request.identifier)
    }
    
    // MARK: - GeTuiSdkDelegate
    /** SDK启动成功返回cid */
    func geTuiSdkDidRegisterClient(_ clientId: String!) {
        // [4-EXT-1]: 个推SDK已注册，返回clientId
        NSLog("\n>>>[GeTuiSdk RegisterClient]:%@\n\n", clientId);
    }
    
    /** SDK遇到错误回调 */
    func geTuiSdkDidOccurError(_ error: Error!) {
        // [EXT]:个推错误报告，集成步骤发生的任何错误都在这里通知，如果集成后，无法正常收到消息，查看这里的通知。
        NSLog("\n>>>[GeTuiSdk error]:%@\n\n", error.localizedDescription);
    }
    
    /** SDK收到sendMessage消息回调 */
    func geTuiSdkDidSendMessage(_ messageId: String!, result: Int32) {
        // [4-EXT]:发送上行消息结果反馈
        let msg:String = "sendmessage=\(messageId),result=\(result)";
        print("\n>>>[GeTuiSdk DidSendMessage]:%@\n\n",msg);
    }
    
    //在alerttime后显示本地推送信息
    func registerNotification(alerTime:Int, toUrl: String, title: String, body: String) {
        // 使用 UNUserNotificationCenter 来管理通知
        let center = UNUserNotificationCenter.current()
        //需创建一个包含待通知内容的 UNMutableNotificationContent 对象，注意不是 UNNotificationContent ,此对象为不可变对象。
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: title, arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: body, arguments: nil)
        content.sound = UNNotificationSound.default()
        // 在 alertTime 后推送本地推送
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(alerTime), repeats: false)
        let request = UNNotificationRequest(identifier: toUrl, content: content, trigger: trigger)
        //添加推送成功后的处理！
        center.add(request) { (error:Error?) in
        }
    }
    
    func geTuiSdkDidReceivePayloadData(_ payloadData: Data!, andTaskId taskId: String!, andMsgId msgId: String!, andOffLine offLine: Bool, fromGtAppId appId: String!) {
        //第一次下载app的时候
        if(!viewController.isFirstStartApp()) {
            let json = try? JSONSerialization.jsonObject(with: payloadData!,options:.allowFragments) as! [String: Any]
            let toUrl = json?["http"]
            let title = json?["title"]
            let body = json?["body"]
            //app不在前台
            if(offLine) {
                if(toUrl != nil) {
                    let msg:String = "Receive Payload: \(toUrl!), taskId:\(taskId), messageId:\(msgId)";
                    viewController.showPage(toUrl as! String!)
                    print("\n>>>[GeTuiSdk DidReceivePayload]:%@\n\n",msg);
                }
            } else {//app在前台
                if(toUrl != nil && title != nil && body != nil) {
                    registerNotification(alerTime: 1, toUrl: toUrl as! String, title: title as! String, body: body as! String)
                }
                
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("applicationWillResignActive");
        GeTuiSdk.resetBadge()
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("applicationDidEnterBackground");
        GeTuiSdk.resetBadge()
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("applicationWillEnterForeground");
        GeTuiSdk.resetBadge()
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        GeTuiSdk.resetBadge()
        UIApplication.shared.applicationIconBadgeNumber = 0;
        print("applicationDidBecomeActive")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        print("applicationWillTerminate");
        GeTuiSdk.resetBadge()
        UIApplication.shared.applicationIconBadgeNumber = 0;
    }


}

