require_relative "lib/dvdvrconv/version"

Gem::Specification.new do |spec|
  spec.name = "dvdvrconv"
  spec.version = Dvdvrconv::VERSION
  spec.authors = ["icm7216"]
  spec.email = ["icm7216d@gmail.com"]

  spec.summary = %q{DVD-VR utility}
  spec.description = %q{This tool converts "vor" file on DVD-VR format disc to "vob" files.}
  spec.homepage = "https://github.com/icm7216/dvdvrconv"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "test-unit"
  spec.add_development_dependency "test-unit-rr"
end
