Pod::Spec.new do |s|
  s.name     = 'TRON'
  s.version      = "5.0.0-beta.5"
  s.license  = 'MIT'
  s.summary  = 'Lightweight network abstraction layer, written on top of Alamofire'
  s.homepage = 'https://github.com/MLSDev/TRON'
  s.authors  = { 'Denys Telezhkin' => 'denys.telezhkin.oss@gmail.com' }
  s.social_media_url = 'https://twitter.com/MLSDevCom'
  s.source   = { :git => 'https://github.com/MLSDev/TRON.git', :tag => s.version.to_s }
  s.requires_arc = true
  s.swift_versions = ['4.0', '4.2', '5.0']
  s.ios.deployment_target = '10.0'
  s.tvos.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'
  s.watchos.deployment_target = '3.0'

  s.dependency 'Alamofire' , '~> 5.0.0-rc.1'

  s.subspec 'Core' do |core|
      core.ios.frameworks = 'UIKit'
      core.source_files = 'Source/TRON/*.swift'
  end

  s.subspec 'SwiftyJSON' do |swiftyjson|
      swiftyjson.dependency 'TRON/Core'
      swiftyjson.dependency 'SwiftyJSON', '~> 5.0'
      swiftyjson.source_files = 'Source/TRONSwiftyJSON/SwiftyJSONDecodable.swift'
  end

  s.subspec 'RxSwift' do |rxswift|
      rxswift.dependency 'TRON/Core'
      rxswift.dependency 'RxSwift', '~> 5.0'
      rxswift.source_files = 'Source/RxTRON/Tron+RxSwift.swift'
  end

  s.default_subspec = 'Core'
end
