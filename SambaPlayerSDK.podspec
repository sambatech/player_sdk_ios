Pod::Spec.new do |s|
	s.name = 'SambaPlayerSDK'
	s.version = '0.1.0'
	s.license = { :type => 'MIT', :file => 'LICENSE' }
	s.summary = 'Samba Tech's media player SDK for iOS'
	s.homepage = 'http://sambatech.com'
	s.authors = { 'Samba Tech Player Team' => 'player@sambatech.com' }
	s.source = { :git => 'https://github.com/sambatech/player_sdk_ios', :tag => s.version }

	s.ios.deployment_target = '8.0'

	s.preserve_paths = 'vendor/'
	s.vendored_frameworks = 'vendor/GoogleAds-IMA-iOS-SDK.framework'
	s.source_files = 'Source/*.swift'
end
