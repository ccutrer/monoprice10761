require_relative "lib/monoprice10761/version"

Gem::Specification.new do |s|
  s.name = 'monopricec10761'
  s.version = Monoprice10761::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Cody Cutrer"]
  s.email = "cody@cutrer.com'"
  s.homepage = "https://github.com/ccutrer/monoprice10761"
  s.summary = "Library for communication with Monoprice 10761 Multi-Zone Amp"
  s.license = "MIT"

  s.bindir = 'exe'
  s.executables = ['monoprice10761_mqtt_bridge']
  s.files = Dir["{exe,lib}/**/*"]

  s.add_dependency 'homie-mqtt', "~> 1.2"
  s.add_dependency 'net-telnet-rfc2217', "~> 1.0"
  s.add_dependency 'ccutrer-serialport', "~> 1.1"

  s.add_development_dependency 'byebug', "~> 9.0"
  s.add_development_dependency 'rake', "~> 13.0"
end
