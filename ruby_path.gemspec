# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)

require 'ruby_path/version'

Gem::Specification.new do |s|
  s.name        = "ruby_path"
  s.version     = RubyPath::VERSION
  s.date        = "2014-01-01"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Sergey Zelvenskiy']
  s.email       = ['sergey@actions.im']
  s.homepage    = 'https://github.com/actions/rubypath'
  s.summary     = %q{Ruby take on JsonPath. Easily extract data from complex ruby data structures coming from parsed JSON. }
  s.description = %q{}

  s.rubyforge_project = 'ruby_path'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-expectations'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'oj'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
