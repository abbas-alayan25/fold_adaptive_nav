Pod::Spec.new do |s|
  s.name             = 'fold_adaptive_nav_ios'
  s.version          = '1.0.0'
  s.summary          = 'iOS implementation of fold_adaptive_nav.'
  s.description      = <<-DESC
Hinge posture, fold and camera regions, size classes and the vertical system
bar on iPhone Duo, for the fold_adaptive_nav Flutter plugin.
                       DESC
  s.homepage         = 'https://github.com/abbas-alayan25/fold_adaptive_nav'
  s.license          = { :type => 'BSD-3-Clause', :file => '../LICENSE' }
  s.author           = { 'Abbas Alayan' => 'abbasalayan1222@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'fold_adaptive_nav_ios/Sources/fold_adaptive_nav_ios/**/*.swift'
  s.resource_bundles = { 'fold_adaptive_nav_ios_privacy' => ['fold_adaptive_nav_ios/Sources/fold_adaptive_nav_ios/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    # The typed iOS 27.1 API path. Remove this flag to build with an older
    # Xcode; the plugin then resolves the same APIs through the ObjC runtime.
    # 'OTHER_SWIFT_FLAGS' => '$(inherited) -DFOLD_NATIVE_API',
  }
end
