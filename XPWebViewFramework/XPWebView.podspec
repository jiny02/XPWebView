Pod::Spec.new do |s|

  s.name         = "XPWebView"
  s.version      = "1.0.5"
  s.summary      = "用于uiwebview的进度条显示和网页来源显示"
  s.homepage     = "https://github.com/jinye19910223/XPWebView"
  s.license      = "MIT"
  s.author       = { "jiny" => "625059135@qq.com" }
  s.platform     = :ios
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/jinye19910223/XPWebView", :tag => "1.0.5" }
  s.source_files  = "XPWebViewFramework/XPWebView/XPWebView.swift"
  s.framework  = "UIKit"
end
