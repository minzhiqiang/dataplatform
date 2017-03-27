//
//  ViewController.swift
//  dataplatform
//
//  Created by minzhiqiang on 16/12/30.
//  Copyright © 2016年 minzhiqiang. All rights reserved.
//

import UIKit
import JavaScriptCore

struct MyRegex {
    let regex: NSRegularExpression?
    
    init(_ pattern: String) {
        regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }
    
    func match(input: String) -> Bool {
        if let matches = regex?.matches(in: input,
                                                options: [],
                                                range: NSMakeRange(0, (input as NSString).length)) {
            return matches.count > 0
        }
        else {
            return false
        }
    }
}

class ViewController: UIViewController,UIWebViewDelegate {
    
    @IBOutlet weak var webView: UIWebView!
    var path: String = ""
    var username: String = ""
    
    //检查更新
    func checkUpdate() {
        PgyUpdateManager.sharedPgy().start(withAppId: "b7295b16c57d06a63f1cfcab923e0752");
        PgyUpdateManager.sharedPgy().checkUpdate();
    }
    
    //检测用户是否第一次启动应用
    func isFirstStartApp() -> Bool {
        return UserDefaults.standard.bool(forKey: "firstLaunch")
    }
    
    /**
     *  检测url是否正确
     */
    func requestUrl(urlString: String) -> Bool {
        var returnFlag = true;
        //链接校验
        let regEx = "^(http|https|ftp)\\://([a-zA-Z0-9\\.\\-]+(\\:[a-zA-"
            + "Z0-9\\.&%\\$\\-]+)*@)?((25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{"
            + "2}|[1-9]{1}[0-9]{1}|[1-9])\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}"
            + "[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|"
            + "[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-"
            + "4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])|([a-zA-Z0"
            + "-9\\-]+\\.)*[a-zA-Z0-9\\-]+\\.[a-zA-Z]{2,4})(\\:[0-9]+)?(/"
            + "[^/][a-zA-Z0-9\\.\\,\\?\\'\\\\/\\+&%\\$\\=~_\\-@]*)*$";
        let matcher = MyRegex(regEx)
        if matcher.match(input: urlString) {
            let url: NSURL = NSURL(string: urlString)!
            let request: NSMutableURLRequest = NSMutableURLRequest(url: url as URL)
            request.timeoutInterval = 5
            do {
                
                let mySession = URLSession(configuration: URLSessionConfiguration.default)
                var goin = true;
                var requestCount = 0;
                while goin {
                    if(requestCount == 0) {
                        let dataTask = mySession.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) in
                            if let httpResponse = response as? HTTPURLResponse {
                                if httpResponse.statusCode == 200 {
                                    print("response:\(httpResponse.statusCode)")
                                }
                            } else {
                                returnFlag = false;
                            }
                            goin = false;
                        })
                        dataTask.resume();
                        requestCount = 1;
                    }

                }
                return returnFlag;
                
            }
            catch (let error) {
                print("error:\(error)")
                return false
            }
        } else{
            return false
        }
    }
    
    //跳转页面方法
    func showPage(_ path: String!) {
        if(requestUrl(urlString: path)) {
            webView.loadRequest(URLRequest(url: URL(string:path)!))

        }
    }
    
    //添加webView
    func addWebView() {
        let width = self.view.bounds.width.description
        let height = self.view.bounds.height.description
        let fwidth = (width as NSString).floatValue
        let fheight = (height as NSString).floatValue//屏幕高度
        let sizewebview:CGFloat = CGFloat(fwidth)
        let posywebview:CGFloat = CGFloat(fheight - 60)
        self.webView.delegate = self
        self.webView.scalesPageToFit = true
        webView.frame = CGRect.init(x: 0, y: 20, width: sizewebview, height: posywebview)
        let indexPath = "http://d.dangdang.com";
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        if(requestUrl(urlString: indexPath)) {
            webView.loadRequest(URLRequest(url: URL(string:indexPath)!))
        } else {
            let jsPath = Bundle.main.path(forResource: "404",ofType:"html")
            webView.loadRequest(URLRequest(url: URL(string:jsPath!)!))
        }
    }
    
    //绑定用户名
    func bindUsername(username: String){
        print(">>>绑定用户名:%@",username);
        print(">>>[GeTui clientId]:%@",GeTuiSdk.clientId());
        GeTuiSdk.bindAlias(username, andSequenceNum: GeTuiSdk.clientId())
    }
    
    //连接改变时
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool{
        let title = webView.stringByEvaluatingJavaScript(from: "document.title");
        username += webView.stringByEvaluatingJavaScript(from: "document.getElementById('username').value")! + "@";
        if(title == "运营数据工具" || title == "当当数据平台-首页导航") {
            var usernameArr = username.components(separatedBy: "@");
            if(usernameArr[usernameArr.count - 3] != "") {
                bindUsername(username: usernameArr[usernameArr.count - 3]);
            }
        }
        return true;
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        //获取我们名为app.js的脚本路径
        let jsPath =  Bundle.main.path(forResource: "app", ofType: "js")
        //获取到脚本中的内容
        var jsString :String = try! String(contentsOfFile: jsPath!, encoding: String.Encoding(rawValue: 4))
        //将获得的文本内容后面的\n替换为空的字符串
        jsString = jsString.replacingOccurrences(of: "\n", with: "");
        //触发脚本
        webView.stringByEvaluatingJavaScript(from: jsString as String)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        checkUpdate();
        //---------- viewcontroller的实例赋予AppDelegate -------------
        let appdelegate = UIApplication.shared.delegate as! AppDelegate;
        appdelegate.viewController = self;
        addWebView();
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doRefresh(_:AnyObject) {
        webView.reload()
    }
    
    @IBAction func goBack(_:AnyObject) {
        webView.goBack()
    }
    
    @IBAction func goForward(_:AnyObject) {
        webView.goForward()
    }
    
    @IBAction func stop(_:AnyObject) {
        webView.stopLoading()
    }
    
    
}
