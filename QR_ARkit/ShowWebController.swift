//
//  ShowWebController.swift
//  QR_ARkit
//
//  Created by Joe Chen on 2019/6/20.
//  Copyright © 2019 Joe Chen. All rights reserved.
//

import UIKit
import WebKit

protocol resetTrackingDelegate {
    
    func resetTracking()
    
}

class ShowWebController: UIViewController,WKNavigationDelegate,WKUIDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var webProgressBar: UIProgressView!
    var webURL : String = ""
    var resetTrackingDelegate : resetTrackingDelegate?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        
        let urlStr = webURL
        if let url = URL(string: urlStr) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        // Do any additional setup after loading the view.
        self.webView.allowsBackForwardNavigationGestures = true
        self.webView.allowsLinkPreview = true
        self.webView .addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress"{
            webProgressBar.alpha = 1.0
            webProgressBar.setProgress(Float((self.webView?.estimatedProgress) ?? 0), animated: true)
            if (self.webView?.estimatedProgress ?? 0.0)  >= 1.0 {
                UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut, animations: {
                    self.webProgressBar.alpha = 0
                }, completion: { (finish) in
                    self.webProgressBar.setProgress(0.0, animated: false)
                })
            }
        }
        
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.webProgressBar.isHidden = false
        activityIndicator.startAnimating()

    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let alert = UIAlertController(title: "", message: "Fail to load the website", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default){ (_) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webProgressBar.isHidden = true
        activityIndicator.stopAnimating()
    }
    
    @IBAction func backToAR(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    deinit {
        self.resetTrackingDelegate?.resetTracking()
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress")

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
