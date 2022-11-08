#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint rtmp_publisher.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'yourinrolltoolsstream'
  s.version          = '1.0.0'
  s.summary          = 'FLutter plugin to allow rtmp yourinrolltoolsstream to work with ios.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/Xatiko540/yourinrolltoolsstream'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'WhelkSoft' => 'YouinRoll.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'HaishinKit', '~> 1.0.10'
  s.platform = :ios, '12.1'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.2'
end