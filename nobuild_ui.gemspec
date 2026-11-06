require_relative "lib/nobuild_ui/version"

Gem::Specification.new do |spec|
  spec.name = "nobuild_ui"
  spec.version = NobuildUi::VERSION
  spec.authors = [ "Martin Business Consultants" ]
  spec.summary = "shadcn/ui for Rails with no build step: plain CSS, Stimulus and view helpers"
  spec.homepage = "https://github.com/Martin-Business-Consultants/nobuild-ui"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["{app,config,lib}/**/*", "LICENSE", "README.md"]
  spec.require_paths = [ "lib" ]

  spec.add_dependency "railties", ">= 7.1"
  spec.add_dependency "actionview", ">= 7.1"
end
