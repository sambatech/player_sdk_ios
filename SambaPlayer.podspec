Pod::Spec.new do |s|
	s.name = 'SambaPlayerSDK'
	s.version = '0.1.0'
	s.license = { :type => 'MIT', :file => 'LICENSE' }
	s.summary = 'Samba Tech media player SDK for iOS'
	s.homepage = 'http://sambatech.com'
	s.authors = { 'Samba Tech Player Team' => 'player@sambatech.com' }
	s.source = { :git => 'https://github.com/sambatech/player_sdk_ios.git', :tag => s.version.to_s }

	s.ios.deployment_target = '8.0'

	s.dependency 'GoogleAds-IMA-iOS-SDK', '~> 3.2.1'
	
	s.source_files = 'SambaPlayer/*.swift', 'GoogleMediaFramework/*.{h,m}'
	s.resource_bundles = { 'SambaPlayerSDK' => ['Resources/**'] }
end
