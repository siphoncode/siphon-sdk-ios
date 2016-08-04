#
# Be sure to run `pod lib lint Siphon.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Siphon"
  s.version          = "0.5.0"
  s.summary          = "A short description of Siphon."

  s.homepage         = "https://getsiphon.com"
  s.author           = { "Siphon" => "hello@getsiphon.com" }

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'SiphonSDK/SiphonSDK/**/*{*.h,*.m}'

  s.resource_bundles = {
    'SiphonResources' => ['SiphonSDK/SiphonSDK/Supporting Files/{pre-header,header,sandbox-header,header-dev,sandbox-header-dev}']
  }

  s.dependency 'React', '0.22.2'
  s.dependency 'SSZipArchive', '0.3.3'
  s.dependency 'SocketRocket', '0.4.2'
  s.dependency 'Mixpanel', '2.9.0'

end
