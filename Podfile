source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target "Soundtrack_final" do
	pod 'SwiftyJSON'
	pod 'AFNetworking'
	pod 'Lockbox'
	pod 'RSKImageCropper'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end