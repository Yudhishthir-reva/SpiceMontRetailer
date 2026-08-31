# Uncomment the next line to define a global platform for your project
platform :ios, '18.0'

target 'SpiceMontRetailer' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SpiceMontRetailer
  pod 'FirebaseCore'
  pod 'FirebaseMessaging'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
end
