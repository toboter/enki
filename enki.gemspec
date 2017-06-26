$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "enki/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "enki"
  s.version     = Enki::VERSION
  s.authors     = ["Tobias Schmidt"]
  s.email       = ["t.schmidt@rubidat.de"]
  s.homepage    = "http://babylon-online.org"
  s.summary     = "Sharing and record stamping."
  s.description = "Sharing and record stamping."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.0"
  s.add_dependency "shareable_models"

  s.add_development_dependency "sqlite3"
end
