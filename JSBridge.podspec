#
# Be sure to run `pod lib lint JSBridge.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JSBridge'
  s.version          = '0.1.0'
  s.summary          = 'H5 与 Native 交互框架'


  s.description      = "H5 与 Native 交互框架"

  s.homepage         = 'https://github.com/yizhaorong/JSBridge'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'yizhaorong' => '243653385@qq.com' }
  s.source           = { :git => 'https://github.com/yizhaorong/JSBridge.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'JSBridge/Classes/**/*'
  
  # s.resource_bundles = {
  #   'JSBridge' => ['JSBridge/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
