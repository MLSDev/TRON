Pod::Spec.new do |s|
  s.name     = 'TRON'
  s.version  = '0.1.1'
  s.license  = 'MIT'
  s.summary  = 'Lightweight network abstraction layer, written on top of Alamofire and SwiftyJSON'
  s.homepage = 'https://github.com/MLSDev/TRON'
  s.authors  = { 'Denys Telezhkin' => 'denys.telezhkin@yandex.ru' }
  s.social_media_url = 'https://twitter.com/MLSDevCom'
  s.source   = { :git => 'https://github.com/MLSDev/TRON.git', :tag => s.version.to_s }
  s.source_files = 'Source/*.swift'
  s.tvos.exclude_files = "Source/NetworkActivityPlugin.swift"
  s.osx.exclude_files = "Source/NetworkActivityPlugin.swift"
  s.watchos.exclude_files = "Source/NetworkActivityPlugin.swift"
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.frameworks = 'Foundation'
  s.ios.frameworks = 'UIKit'
  s.dependency 'Alamofire' , '~> 3.1'
  s.dependency 'SwiftyJSON', '~> 2.3'
end
