source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target "Soundtrack_final" do
	pod 'SwiftyJSON', '< 3.1.4'
	pod 'AFNetworking'
	pod 'Lockbox'
	pod 'RSKImageCropper'
	pod 'Material', '~> 2.0'
	pod 'PopupDialog', '~> 0.5'
	pod 'HDAugmentedReality', :git => 'https://github.com/DanijelHuis/HDAugmentedReality.git'
	pod 'Upsurge'
	pod 'Charts'
	pod "RQShineLabel"
	pod 'PageMenu'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end