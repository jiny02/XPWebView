//
//  XPWebView.swift
//  XPWebViewTest
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 - 2015 Fabrizio Brancati. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

@objc public protocol WebViewProxyDelegate {
    @objc optional func webViewDidFinishLoad(_ webView: UIWebView)
    @objc optional func webViewDidStartLoad(_ webView: UIWebView)
    @objc optional func webView(_ webView: UIWebView, didFailLoadWithError error: NSError?)
    @objc optional func webView(_ webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool
}

extension XPWebView{
    func belongViewController() -> UIViewController? {
        var responder:UIResponder? = self.next()
        while (responder != nil) {
            if responder is UIViewController {
                let currentVC:UIViewController = (responder! as!UIViewController)
                return currentVC
            }
            responder = responder?.next()
        }
        return nil
    }
}

@IBDesignable public class XPWebView: UIWebView {
    var sourceLabel:UILabel?
    var progressView:UIProgressView?
    var maxLoadCount:Double! = 0
    var loadingCount:Double! = 0
    var currentUrl:NSURL?
    var interactive:Bool! = false
    var webViewProxyDelegate:WebViewProxyDelegate?
   @IBInspectable public var  remoteUrl:String?{
        willSet(newremoteUrl) {
            let urlEncode = newremoteUrl?.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed())
            let url = URL(string:urlEncode!)
            let urlRequest:URLRequest! = URLRequest(url: url!)
            self.loadRequest(urlRequest! as URLRequest)
            sourceLabel = UILabel(frame: CGRect(x: 0, y: 10, width: UIScreen.main().bounds.size.width, height: 15))
            let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
            let item = components?.host
            if item == nil {
                print("url格式不正确")
                return
            }
            sourceLabel?.text = ("网页由 \((url!.host)!) 提供")
            sourceLabel?.font = .systemFont(ofSize: 12)
            sourceLabel?.textColor = .white()
            sourceLabel?.textAlignment = .center
            if sourceLabel?.superview == nil {
                self.scrollView.addSubview(sourceLabel!)
                self.scrollView.sendSubview(toBack: sourceLabel!)
            }
        }
    }
    
    override public func awakeFromNib() {
        self.delegate = self
        progressView = UIProgressView()
        progressView?.progress = 0.1
        self.addSubview(progressView!)
    }
    
    // MARK: 网页是否加载完成
    func loadComplete(webView:UIWebView) -> Bool {
        let readyState:String! = webView.stringByEvaluatingJavaScript(from: "document.readyState")!
        if readyState == "interactive" {
            interactive = true
            let waitForCompleteJS:String = "window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = 'webviewprogressproxy:///complete'; document.body.appendChild(iframe);  }, false);"
            webView.stringByEvaluatingJavaScript(from: waitForCompleteJS)
        }
        if (readyState == "complete") && (currentUrl != nil) && (currentUrl == webView.request?.mainDocumentURL) {
            self.completeProgress()
            return true
        }
        return false
    }
    
    // MARK: 进度显示
    func incrementProgress() {
        var progress:Float = (progressView?.progress)!
        var maxProgress:Float?
        if interactive == true {
            maxProgress = 0.9
        }
        else{
            maxProgress = 0.5
        }
        let remainPercent:Float = Float(loadingCount!)/Float(maxLoadCount!)
        let increment:Float = (maxProgress! - progress)*remainPercent
        progress += increment
        progress = fmin(progress, maxProgress!)
        if progress >= (progressView?.progress)! {
            progressView?.setProgress(progress, animated: true)
        }
    }
    
    // MARK: 加载完成后
    func completeProgress() {
        if progressView?.isHidden == true {
            return
        }
        Timer.scheduledTimer(timeInterval: 0.6, target: self, selector: #selector(self.hiddenProgressView), userInfo: nil, repeats: false)
    }
    
    // MARK: 重定向后重置进度
    func resetProgress() {
        maxLoadCount = 0
        loadingCount = 0
        interactive = false
        progressView?.isHidden = false
        progressView?.progress = 0.1
    }
    
    func hiddenProgressView() {
        progressView?.isHidden = true
    }
    
    func updateProgressFrame() {
        if self.belongViewController()?.automaticallyAdjustsScrollViewInsets == true {
            progressView?.frame = CGRect(x: 0, y: 64, width: UIScreen.main().bounds.size.width, height: 2)
        }else{
            progressView?.frame = CGRect(x: 0, y: 0, width: UIScreen.main().bounds.size.width, height: 2)
        }
    }
}

extension XPWebView{
    override public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if sourceLabel != nil {
            var headFrame:CGRect! = sourceLabel?.frame
            headFrame.origin.y = scrollView.contentOffset.y + 10 + 64
            sourceLabel?.frame = headFrame
        }
    }
}

extension XPWebView:UIWebViewDelegate{
    public func webViewDidStartLoad(_ webView: UIWebView) {
        if (webViewProxyDelegate != nil) && (webViewProxyDelegate?.webViewDidStartLoad!(webView) != nil) {
            webViewProxyDelegate?.webViewDidStartLoad!(webView)
        }
        loadingCount! += 1
        maxLoadCount = fmax(maxLoadCount, loadingCount)
        if (progressView?.progress)! <= 0.1 {
            progressView?.setProgress(0.1, animated: true)
        }
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        if (webViewProxyDelegate != nil) && (webViewProxyDelegate?.webViewDidFinishLoad!(webView) != nil) {
            webViewProxyDelegate?.webViewDidFinishLoad!(webView)
        }
        loadingCount! -= 1
        incrementProgress()
        let _ = loadComplete(webView: webView)
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: NSError?) {
        if (webViewProxyDelegate != nil) && (webViewProxyDelegate?.webView!(webView, didFailLoadWithError: error) != nil) {
            webViewProxyDelegate?.webView!(webView, didFailLoadWithError: error)
        }
        loadingCount! -= 1
        self.incrementProgress()
        let _ = self.loadComplete(webView: webView)
    }
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url?.host != nil{
            if sourceLabel != nil {
                sourceLabel?.text = ("网页由 \((request.url?.host)!) 提供")
            }
        }
        self.updateProgressFrame()
        if (request.url?.absoluteString == "webviewprogressproxy:///complete") {
            self.completeProgress()
            return false
        }
        var ret:Bool! = true
        if (webViewProxyDelegate != nil) && (webViewProxyDelegate?.webView!(webView, shouldStartLoadWithRequest: request, navigationType: navigationType) != nil) {
            ret = webViewProxyDelegate?.webView!(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
        }
        var isFragmentJump:Bool! = false
        if request.url?.fragment != nil {
            let nonFragmentUrl:String = (request.url?.absoluteString?.replacingOccurrences(of: "#".appending((request.url?.fragment)!), with: ""))!
            isFragmentJump = (nonFragmentUrl == webView.request?.url?.absoluteString)
        }
        let isTopLevelNavigation:Bool! = (request.mainDocumentURL == request.url)
        let isHTTP:Bool = ((request.url!.scheme == "http") || (request.url?.scheme == "https"))
        if ((ret == true) && (isFragmentJump == false) && (isHTTP == true) && (isTopLevelNavigation == true)) {
            currentUrl = request.url
            self.resetProgress()
        }
        return ret
    }
}

