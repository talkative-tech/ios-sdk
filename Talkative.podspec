#
# Be sure to run `pod lib lint Talkative.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Talkative'
  s.version          = '0.4.0'
  s.summary          = 'Talkative lets you connect with customers on their channel of choice.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'The Best Way to Engage with your Customers, from video chat to virtual agent, Talkative lets you connect with customers on their channel of choice.'

  s.homepage         = 'https://github.com/talkative-tech/ios-sdk'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'All rights reserved.' }
  s.author           = { 'Talkative' => 'support@talkative.uk' }
  s.source           = { :git => 'https://github.com/talkative-tech/ios-sdk.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.swift_version = '5.0'
  s.cocoapods_version = '>= 1.10.0'
  s.ios.deployment_target = '14.5'

  s.source_files = 'Classes/**/*'
  
  # s.resource_bundles = {
  #   'Talkative' => ['Talkative/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
