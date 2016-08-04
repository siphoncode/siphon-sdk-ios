Pod::Spec.new do |s|
  s.name             = 'Siphon'
  s.version          = '0.5.0'
  s.summary          = 'Build React Native apps easily.'
  s.author           = { "Siphon" => "hello@getsiphon.com" }
  s.homepage         = "https://getsiphon.com"
  s.source           = { :git => 'https://bitbucket.org/getsiphon/siphon-sdk-ios.git' }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = ['SiphonSDK/Build/Products/Release-universal/SiphonSDKHeaders/SPAppViewController.h',
                    'SiphonSDK/Build/Products/Release-universal/SiphonSDKHeaders/SPDevelopmentAppViewController.h']
  s.vendored_libraries = 'SiphonSDK/Build/Products/Release-universal/libSiphonSDK.a'
  s.public_header_files = ['SiphonSDK/Build/Products/Release-universal/SiphonSDKHeaders/SPAppViewController.h',
                           'SiphonSDK/Build/Products/Release-universal/SiphonSDKHeaders/SPDevelopmentAppViewController.h']

  s.resource_bundles = {
    'SiphonResources' => ['SiphonSDK/SiphonSDK/Supporting Files/{pre-header,header,sandbox-header,header-dev,sandbox-header-dev}']
  }

  s.dependency 'React', '0.22.2'
  s.dependency 'SSZipArchive', '0.3.3'
  s.dependency 'SocketRocket', '0.4.2'
  s.dependency 'Mixpanel', '2.9.0'

end
