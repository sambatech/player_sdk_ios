Pod::Spec.new do |s|
	s.name = 'SambaPlayerSDK'
	s.version = '0.1.0'
	s.license = { :type => 'MIT', :file => 'LICENSE' }
	s.summary = 'Samba Tech media player SDK for iOS'
	s.homepage = 'http://sambatech.com'
	s.authors = { 'Samba Tech Player Team' => 'player@sambatech.com' }
	s.source = { :git => 'https://github.com/sambatech/player_sdk_ios.git', :tag => String(s.version) }

	s.ios.deployment_target = '8.0'

	s.preserve_paths = 'Vendor'
	s.vendored_frameworks = 'Vendor/GoogleInteractiveMediaAds.framework'
	s.dependency 'Alamofire', '~> 3.4'

	s.source_files = 'Source/*.swift', 'Vendor/GoogleMediaFramework'
	s.resources = 'Vendor/GoogleMediaFramework/Resources/**'
end
