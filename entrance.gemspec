# -*- encoding: utf-8 -*-
require File.expand_path("../lib/dimension/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "entrance"
  s.version     = Entrance
  ::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Tomás Pollak']
  s.email       = ['tomas@forkhq.com']
  s.homepage    = "https://github.com/tomas/entrance"
  s.summary     = "Lean authentication alternative for Rails and Sinatra."
  s.description = "Doesn't fiddle with your controllers and routes."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "entrance"
  
  s.add_runtime_dependency "bcrypt", ">= 3.0.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
  # s.bindir       = 'bin'
end
