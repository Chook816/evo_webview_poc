//
//  WebViewViewController.swift
//  POC_WebView
//
//  Created by Apple on 12/11/20.
//

import Foundation
import WebKit
import Photos

class WebViewViewController: UIViewController,WKNavigationDelegate, WKScriptMessageHandler, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var loadingCircle: UIActivityIndicatorView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var sessionTimeoutButton: UIButton!
    
    var webView: WKWebView!
    var userToken: String? = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        createToken()
        webviewSetup()
        logoutButton.addTarget(self, action: #selector(logoutDidTapped), for: .touchUpInside)
        sessionTimeoutButton.addTarget(self, action: #selector(sessionTimeoutDidTapped), for: .touchUpInside)
    }
    
    func createToken()  {
        let length = 24
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        userToken = String((0..<length).map{ _ in letters.randomElement()! })
        print("currentToken",userToken)
    }
    
    func webviewSetup(){
        webView = WKWebView(frame: self.containerView.frame)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        let url = URL(string: "http://127.0.0.1:3000/")! // URL of local website
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
        containerView.addSubview(webView)
        // Setup for receive message
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "toggleMessageHandler")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // send token to website when first init
        webView!.evaluateJavaScript("receiveToken('\(userToken!)')", completionHandler: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            print("---Clear token---")
            // clear token when dismiss
            webView!.evaluateJavaScript("deleteToken()", completionHandler: nil)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // listener
        guard let dict = message.body as? [String : AnyObject] else {
            return
        }
        guard let type = dict["type"] as? String ?? "" else {
            return
        }
        guard let msgRecive = dict["msg"] as? String ?? "" else {
            return
        }
        guard let token = dict["token"] as? String ?? "" else {
            return
        }
        switch type {
        case "logout":
            print(msgRecive)
        //            logOut()
        case "deletetoken":
            print(msgRecive)
        case "imagePermission":
            print(msgRecive)
            requestPermission()
        default:
            print("none")
        }
    }
    
    func logOut(){
        dismiss(animated: true, completion: .none)
    }
    
    func requestPermission(){
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            print("already authorized")
            openPhotoLibrary()
        } else {
            PHPhotoLibrary.requestAuthorization({(_ status: PHAuthorizationStatus) -> Void in
                switch status {
                case .authorized:
                    print("Authorized")
                case .denied:
                    print("Denied")
                case .notDetermined:
                    print("Not determined")
                case .restricted:
                    print("Restricted")
                case .limited:
                    print("Limited")
                @unknown default:
                    print("Unknown")
                }
            })
        }
    }
    
    func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self;
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
}

// MARK: -Actions
@objc extension WebViewViewController {
    
    func logoutDidTapped() {
        webView!.evaluateJavaScript("logOut()", completionHandler: nil)
        logOut()
    }
    
    func sessionTimeoutDidTapped() {
        webView!.evaluateJavaScript("logOut()", completionHandler: nil)
        navigateToLogin()
    }
    
    func navigateToLogin() {
        let story = UIStoryboard(name: "Main", bundle:nil)
        let loginViewController = story.instantiateViewController(withIdentifier: "LoginViewController") as! ViewController
        UIApplication.shared.windows.first?.rootViewController = loginViewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
}


