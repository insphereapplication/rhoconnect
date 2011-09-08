module VersionCheck
  MIN_APPLE_VERSION = "4"
  MIN_ANDROID_VERSION = "2.2"
  
  def self.unsupported_platform_version?(platform, version)
    min_required_platform_versions = {
      'apple' => Version.new(MIN_APPLE_VERSION),
      'android' => Version.new(MIN_ANDROID_VERSION)
    }
  
    min_platform_version = min_required_platform_versions[platform.downcase]
  
    raise "Unsupported platform #{platform}" unless min_platform_version
  
    min_platform_version > Version.new(version)
  end
end